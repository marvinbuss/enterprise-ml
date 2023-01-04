import os
import json
import logging

import mlflow
import numpy as np

RANDOM_STATE = 0
MODEL_ARTIFACT_NAME = "model"


def init() -> None:
    """Initializes MLFlow model.

    RETURNS (None): Nothing gets returned.
    """
    global model

    model_path = os.path.join(os.environ.get("AZUREML_MODEL_DIR"), MODEL_ARTIFACT_NAME)
    model = mlflow.sklearn.load_model(model_path)


def run(input: str) -> str:
    """Initializes MLFlow model.

    input (str): String containing the raw JSON input.
    RETURNS (str): JSON string containing the response.
    """
    logging.info(f"Received request '{input}'")

    # Convert input
    data = json.loads(input).get("data")
    model_input = np.array(data)

    # Predict
    model_output = model.predict(model_input)

    result = {
        "prediction": model_output.tolist()
    }
    return str(result)
