"""Seed the owned, disposable Orthanc with three synthetic one-pixel instances."""

import argparse
from pydicom.dataset import Dataset, FileMetaDataset
from pynetdicom import AE
from pynetdicom.sop_class import CTImageStorage, MRImageStorage


def instance(study, series, modality, body):
    ds = Dataset()
    ds.file_meta = FileMetaDataset()
    ds.file_meta.TransferSyntaxUID = "1.2.840.10008.1.2.1"
    ds.SOPClassUID = CTImageStorage if modality == "CT" else MRImageStorage
    ds.SOPInstanceUID = f"2.25.8000.{study}.{series}.1"
    ds.StudyInstanceUID = f"2.25.8000.{study}"
    ds.SeriesInstanceUID = f"2.25.8000.{study}.{series}"
    ds.PatientID = f"SYNTH-{study}"
    ds.PatientName = f"SYNTHETIC^{study}"
    ds.AccessionNumber = f"SYNTH-ACC-{study}"
    ds.StudyDate = "20260101" if study == 1 else "20260201"
    ds.StudyTime = "120000"
    ds.StudyDescription = f"Synthetic {modality} study"
    ds.SeriesDescription = f"Synthetic series {series}"
    ds.Modality = modality
    if body:
        ds.BodyPartExamined = body
    ds.SeriesNumber = series
    ds.InstanceNumber = 1
    ds.Rows = ds.Columns = 1
    ds.SamplesPerPixel = 1
    ds.PhotometricInterpretation = "MONOCHROME2"
    ds.BitsAllocated = ds.BitsStored = 16
    ds.HighBit = 15
    ds.PixelRepresentation = 0
    ds.PixelData = b"\0\0"
    return ds


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    args = parser.parse_args()
    ae = AE(ae_title="SYNTH_SEED")
    ae.add_requested_context(CTImageStorage)
    ae.add_requested_context(MRImageStorage)
    assoc = ae.associate("127.0.0.1", args.port, ae_title="PACS_AET")
    if not assoc.is_established:
        raise RuntimeError("Synthetic seed association failed")
    try:
        for spec in [(1, 1, "CT", "CHEST"), (1, 2, "CT", None), (2, 1, "MR", "HEAD")]:
            status = assoc.send_c_store(instance(*spec))
            if not status or status.Status != 0:
                raise RuntimeError("Synthetic seed storage failed")
    finally:
        assoc.release()
    print("Seeded 2 synthetic studies / 3 series / 3 instances.")
