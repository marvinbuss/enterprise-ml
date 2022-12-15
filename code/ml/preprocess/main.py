import os
import argparse
import mlflow


def main(args: argparse.Namespace) -> None:
    """Main function orchestrating the step of the pipeline.

    args (argparse.Namespace): The model that should be used for analyzing the text.
    RETURNS (None): Nothing gets returned.
    """
    with mlflow.start_run() as mlflow_run:
        mlflow.log_param("hello", "world")


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
    parser.add_argument("--tracking-uri", dest="tracking_uri", type=str, help="MLFlow Tracking URL")
    parser.add_argument("--experiment-name", dest="experiment_name", type=str, help="MLFlow experiment name")
    args = parser.parse_args()
    return args


if __name__ == "__main__":
    args = parse_args()
    init_mlflow(
        tracking_uri=args.tracking_uri,
        experiment_name=args.experiment_name,
    )
    main(args=args)
