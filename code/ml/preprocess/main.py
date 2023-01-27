import argparse
import os

import mlflow
import mltable
import pandas as pd
from sklearn.model_selection import train_test_split

RANDOM_STATE = 0


def create_mltable(path: str, file_name: str) -> None:
    """Creates an MLTable definition at the provided path.

    path (str): The path where the MLTable file will be created.
    file_name (str): The file name referenced in the MLTable file.
    RETURNS (None): Nothing gets returned.
    """
    mltable_def = f"""
    type: mltable
    paths:
    - file: ./{file_name}
    transformations:
    - read_parquet:
        include_path_column: false
    """

    with open(os.path.join(path, "MLTable"), "w") as f:
        f.write(mltable_def)


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

        # Create dataframes
        train_df = pd.DataFrame(data=train, columns=df.columns)
        test_df = pd.DataFrame(data=test, columns=df.columns)

        # Log parameters and metrics
        mlflow.log_param("test_size", args.test_size)

        # Save data
        train_file_name = "diabetes.parquet"
        train_df.to_parquet(
            path=os.path.join(args.output_data_train, train_file_name),
            engine="fastparquet",
            compression="snappy",
            index=None,
            partition_cols=None,
            storage_options=None,
        )
        create_mltable(path=args.output_data_train, file_name=train_file_name)

        test_file_name = "diabetes.parquet"
        test_df.to_parquet(
            path=os.path.join(args.output_data_test, test_file_name),
            engine="fastparquet",
            compression="snappy",
            index=None,
            partition_cols=None,
            storage_options=None,
        )
        create_mltable(path=args.output_data_test, file_name=test_file_name)


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
        "--test-size",
        dest="test_size",
        type=float,
        help="Size of the test dataset in percent.",
        default=0.2,
    )
    parser.add_argument(
        "--input-data", dest="input_data", type=str, help="Path to input dataset."
    )
    parser.add_argument(
        "--output-data-train",
        dest="output_data_train",
        type=str,
        help="Path to where train data output should be stored.",
    )
    parser.add_argument(
        "--output-data-test",
        dest="output_data_test",
        type=str,
        help="Path to where test data output should be stored.",
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
