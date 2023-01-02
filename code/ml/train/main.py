import argparse
import os
from typing import List

import mlflow
import mltable
import numpy as np
from sklearn.model_selection import GridSearchCV, train_test_split
from sklearn.svm import SVR

RANDOM_STATE = 0


def compute_value_range(n: int, exp_low: int, exp_high: int) -> List[float]:
    """Returns a list of values to be used for hyperparameter tuning.

    n (int): The number of list items to generate.
    exp_low (int): The lowest exponent to use.
    exp_high (int): The highest exponent to use.
    RETURNS (None): Nothing gets returned.
    """
    base = np.ones(n) + 1
    exp = np.linspace(
        start=exp_low,
        stop=exp_high,
        num=n,
    )
    return (base**exp).tolist()


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

        # Create grid for grid search
        gamma = compute_value_range(5, -10, 4)
        C = compute_value_range(5, -4, 7)
        epsilon = compute_value_range(5, -8, -1)
        parameters = {
            "C": C,
            "gamma": gamma
            if args.svr_kernel in ["rbf", "poly", "sigmoid"]
            else "scale",
            "epsilon": epsilon,
        }

        # Create model
        model = SVR(
            kernel=args.svr_kernel,
            degree=args.svr_degree,
            coef0=0.0,
            tol=0.001,
            shrinking=True,
            cache_size=200,
            verbose=False,
            max_iter=-1,
        )

        # Create grid search
        clf = GridSearchCV(
            estimator=model,
            param_grid=parameters,
            scoring=None,
            n_jobs=-1,
            refit=True,
            cv=None,
            verbose=False,
        )

        # Find best model
        clf.fit(
            X=X,
            y=y,
        )

        # Infer signature
        y_pred = clf.predict(X=X)
        signature = mlflow.models.signature.infer_signature(X, y_pred)

        # Log parameters and metrics
        mlflow.log_param("kernel", args.svr_kernel)
        mlflow.log_param("degree", args.svr_degree)
        mlflow.log_metric("best_score", clf.best_score_)
        mlflow.log_metrics(clf.best_params_)
        mlflow.log_dict(clf.cv_results_, "cv_results.yml")
        mlflow.log_metric("refit_time", clf.refit_time_)
        mlflow.log_metric("cross_validation_splits", clf.n_splits_)

        # Track and copy model to output
        mlflow.sklearn.save_model(
            clf.best_estimator_,
            args.output_data,
            signature=signature,
            input_example=X.sample(n=1),
            metadata={
                "train_run_id": mlflow_run.info.run_id,
                "train_run_name": mlflow_run.info.run_name,
            },
        )


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
        "--svr-kernel",
        dest="svr_kernel",
        choices=["linear", "poly", "rbf", "sigmoid", "precomputed"],
        help="Kernel to use for the Support Vector Regression.",
        default="rbf",
    )
    parser.add_argument(
        "--svr-degree",
        dest="svr_degree",
        type=int,
        help="Degree for poly kernel.",
        default=3,
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
