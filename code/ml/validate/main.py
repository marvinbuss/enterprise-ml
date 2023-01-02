import argparse
import os
from pathlib import Path

import mlflow
import mltable
from sklearn.metrics import (
    explained_variance_score,
    mean_absolute_error,
    mean_squared_error,
    r2_score,
)

RANDOM_STATE = 0


def main(args: argparse.Namespace) -> None:
    """Main function orchestrating the step of the pipeline.

    args (argparse.Namespace): The model that should be used for analyzing the text.
    RETURNS (None): Nothing gets returned.
    """
    tbl = mltable.load(args.input_data)
    df = tbl.to_pandas_dataframe()

    with mlflow.start_run() as mlflow_run:
        # Prepare data
        X, y = df.drop([args.target_column_name], axis=1), df[args.target_column_name]

        # Load model
        cls = mlflow.sklearn.load_model(args.input_model)

        # Use Test Data to calculate accuracy metrics
        y_pred = cls.predict(X=X)
        mae = mean_absolute_error(y_true=y, y_pred=y_pred)
        mse = mean_squared_error(y_true=y, y_pred=y_pred)
        r2s = r2_score(y_true=y, y_pred=y_pred)
        evs = explained_variance_score(y_true=y, y_pred=y_pred)

        # Write score report
        with open(os.path.join(args.output_data, "validation.text"), "w") as f:
            f.write(f"Mean squared error: {mse}")
            f.write(f"Mean absolute error: {mae}")
            f.write(f"R2 score: {r2s}")
            f.write(f"Explained variance score: {evs}")

        # Log parameters and metrics
        mlflow.log_metric("mean_absolute_error", mae)
        mlflow.log_metric("mean_squared_error", mse)
        mlflow.log_metric("r2_score", r2s)
        mlflow.log_metric("explained_variance_score", evs)

        # Get Run ID from model path
        mlmodel_path = os.path.join(args.input_model, "MLmodel")
        run_id = ""
        with open(mlmodel_path, "r") as modelfile:
            for line in modelfile:
                if "run_id" in line:
                    run_id = line.split(":")[1].strip()

        # Construct Model URI from run ID extract previously
        model_uri = f"runs:/{run_id}/outputs/"

        # Register model
        mlflow.register_model(model_uri, args.model_name)


def init_mlflow(tracking_uri: str, experiment_name: str) -> None:
    """Initialized MLFlow if not already done through environment variables.

    tracking_uri (str): The tracking URI for MLFLow.
    experiment_name (str): The name of the experiment name for MLFLow.
    RETURNS (None): Nothing gets returned.
    """
    if not os.environ.get("MLFLOW_TRACKING_URI", default=None):
        mlflow.set_tracking_uri(uri=tracking_uri)
    if not os.environ.get("MLFLOW_EXPERIMENT_NAME", default=None):
        mlflow.set_experiment(experiment_name=experiment_name)


def parse_args() -> argparse.Namespace:
    """Parses command line arguments.

    RETURNS (argparse.Namespace): Arguments parsed from command line.
    """
    parser = argparse.ArgumentParser(description="Arguments for pipeline step")
    parser.add_argument(
        "--tracking-uri", dest="tracking_uri", type=str, help="MLFlow Tracking URL"
    )
    parser.add_argument(
        "--experiment-name",
        dest="experiment_name",
        type=str,
        help="MLFlow experiment name",
    )
    parser.add_argument(
        "--target-column-name",
        dest="target_column_name",
        type=str,
        help="Name of the target column for the regression problem.",
    )
    parser.add_argument(
        "--input-data", dest="input_data", type=str, help="Path to input dataset."
    )
    parser.add_argument(
        "--input-model", dest="input_model", type=str, help="Path to input model."
    )
    parser.add_argument(
        "--model-name",
        dest="model_name",
        type=str,
        help="Model name to use for registration.",
    )
    parser.add_argument(
        "--output-data",
        dest="output_data",
        type=str,
        help="Path to where output should be stored.",
    )
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = parse_args()
    init_mlflow(
        tracking_uri=args.tracking_uri,
        experiment_name=args.experiment_name,
    )
    main(args=args)
