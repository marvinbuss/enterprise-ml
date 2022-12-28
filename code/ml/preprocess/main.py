import argparse
import os
import pickle

import mlflow
import mltable
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

RANDOM_STATE = 0


def main(args: argparse.Namespace) -> None:
    """Main function orchestrating the step of the pipeline.

    args (argparse.Namespace): The model that should be used for analyzing the text.
    RETURNS (None): Nothing gets returned.
    """
    # Load data
    tbl = mltable.load(args.input_data)
    df = tbl.to_pandas_dataframe()

    with mlflow.start_run() as mlflow_run:
        # Train, test split
        train, test = train_test_split(
            df, test_size=args.test_size, random_state=RANDOM_STATE, shuffle=True
        )
        mlflow.log_param("test_size", args.test_size)

        # Normalize data
        scaler = StandardScaler(copy=True, with_mean=True, with_std=True)
        scaler_model = scaler.fit(train)
        train_norm_df = pd.DataFrame(
            data=scaler_model.transform(train), columns=df.columns
        )
        test_norm_df = pd.DataFrame(
            data=scaler_model.transform(test), columns=df.columns
        )

        # Log parameters and metrics
        mean = {
            f"{scaler_model.feature_names_in_[i]}_mean": scaler_model.mean_[i]
            for i in range(len(scaler_model.feature_names_in_))
        }
        scale = {
            f"{scaler_model.feature_names_in_[i]}_std": scaler_model.scale_[i]
            for i in range(len(scaler_model.feature_names_in_))
        }
        mlflow.log_param("test_size", args.test_size)
        mlflow.log_metrics(metrics=mean)
        mlflow.log_metrics(metrics=scale)
        mlflow.sklearn.log_model(scaler_model, "StandardScaler")

        # Save data
        # TODO


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
        "--input-data", dest="input_data", type=str, help="Path to input dataset."
    )
    parser.add_argument(
        "--output-data",
        dest="output_data",
        type=str,
        help="Path to where output should be stored.",
    )
    parser.add_argument(
        "--test-size",
        dest="test_size",
        type=float,
        help="Size of the test dataset in percent.",
        default=0.2,
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
