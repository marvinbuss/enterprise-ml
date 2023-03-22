# Enterprise-ML Reference Implementation

This repository showcases how to do MLOps with Azure Machine Learning and the latest Azure CLI v2. The project showcases how project teams can create a secure machine learning environment using Infrastructure as Code (Bicep), how to structure their machine learning projects in git, how to build reusable components and pipleines and how to productionize these projects. The repository covers the following project phases:

1. Data Discovery,
2. Experimentation,
3. Training,
4. Deployment and 
5. Monitoring.

## Architecture

![Architecture](/docs/images/architecture_single_environment.png)

The image above depicts the architecture of a single environment (dev/test/prod) within an Cloud Scale Data Landing Zone. Core network resources such as vnets, NSGs and Route Tables ae usually provided by a platform team and are used to connect the Azure PaaS services to the corporate network. Shared data lakes within the data landing zone are also used by the data science project team to consume data and produce new data products that can be shared with other teams internally. A shared application layer within the data landing zone can be used by the team to make use of otehr tools such as Azure Databricks for data engineering purposes.

All environment of such a data science setup should reside within the production data landing zone. Different resource groups within the production dta alanding zone should be used to isolate them from one another. This is necessary, as data science teams usually require access to real production data for their use cases. Copying production data into a lower environment is usually also a problematic process or obfuscates the data significantly making it impossible to create meaningful results for data scientists.

## Workflow

![Data Science Workflow](/docs/images/workflow.png)

The workflow diagram above shows the end-to-end lifecycle of a data science process as well as the iterative development processes that need to be followed.

## Model Promotion Scenarios

![Model Promotion Process](/docs/images/model_promotion_scenarios.png)

In order to save cost and not retrain models constantly, Machine learning models can be promoted from a lower into a higher environment (from dev to test to prod) after a successful training run. However, the promotion process can vary significantly as it highly depends where and how the model is expected to run. In some scenarios, the model is expected to be promoted into an application environment, where the model can then be hosted on different compute environments such as Azure ML Online Endpoints or other services that can host containerized applications such as AKS, Azure Webs Apps or Azure Container Apps.

Other scenarios require the model to be hosted in the analytical data platform. Within the data platform, the model might be promoted into in a container platform to serve real-time requests via REST API Calls or be promoted as part of a batch process to score data based on a schedule or other kinds of triggers that kickstart the processing of a larger dataframe. Similar to the application scenarios, Azure ML Online Endpoints, AKS, Azure Web Apps or Azure Container Apps can be used for hosting the model to serve REST API calls. For batch scenarios, the model may be promoted as part of an Azure ML Batch Endpoint or to a database environment to score data in batches directly within the database server.

## Model Promotion Architecture

In this repository, we are focussing on the scenario, where a real-time endpoint should be hsted in the data platform environment. Therefore, we are looking at the scanrio, how a model trained in an Azure Machine Learning workspace in the dev environment can be promoted and rolled out into a higher environment using GitHub Actions, the Azure ML SDK v2 in combination with Bicep IaC.

![Model Promotion Architecture](/docs/images/architecture_model_promotion.png)

The code in this repository implements the steps shown in the architecture above. For cost reasons, the promotion process is just implemented across two environments: development and production. Additional environments can be added easily. It is recommended to have at least three environments in place for proper testing and validation before hiting the production environment.

Linting steps and Python tests are being executed to validate correct functionality of the code early on before it is submitted to any of the Cloud environments and before it is being merged into the main branch. Other workflows are being used to ensure that the IaC is correctly defined and in a deployable state.

When merging code into the main branch, the IaC is deployed to the development environment before the training pipeline is being submitted to the same environment. Upon successful completion of the training run, the resulting model is being deployed and tested. If all previous steps completed successfully, an approval message is being submitted to a Teams channel to notify the engineering team of a new model candidate. From here, the team can jump to Azure ML or GitHub to review the training run as well as the resulting model and decide whether the model should be promoted and rolled out to the production environment.

If the engineering team approved teh promotion, the production workflow is being kicked off, which downloads the new candidate model from the development environment and registers it into the higher environment (test or production). Afterwards, the model is being deployed onto an Azure ML Online Endpoint.
