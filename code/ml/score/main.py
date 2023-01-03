import os
from typing import List

import mlflow
import pandas as pd

RANDOM_STATE = 0
TARGET_COLUMN_NAME = "Y"


def init() -> None:
    """Initializes MLFlow model.

    RETURNS (None): Nothing gets returned.
    """
    global model

    model_path = os.path.join(
        os.environ.get("AZUREML_MODEL_DIR", default=None), "model"
    )
    model = mlflow.sklearn.load_model(model_path)


def run(mini_batch: List[str]) -> pd.DataFrame:
    results = pd.DataFrame(
        columns=[
            "AGE",
            "SEX",
            "BMI",
            "MAP",
            "TC",
            "LDL",
            "HDL",
            "TCH",
            "LTG",
            "GLU",
            TARGET_COLUMN_NAME,
        ]
    )

    for file_path in mini_batch:
        # Read file
        df = pd.read_parquet(
            path=file_path,
            engine="auto",
            columns=None,
            storage_options=None,
            use_nullable_dtypes=False,
        )

        # Predict target column
        y_pred = model.predict(df)

        # Create dataframe
        df[TARGET_COLUMN_NAME] = y_pred

        # Concat results
        results = pd.concat(objs=[results, df])

    return results
