# FMS GuardrailsOrchestrator Performance Test

## Goal
To get an initial assessment of the performance of the FMS Guardrails Orchestrator running on OpenShift AI, compared to a baseline model without guardrails.

## Running performance tests
### Prerequisites
- An OpenShift cluster with at least a GPU node.
- OpenShift AI operator plus all the required operators (Authorino, Serverless, Service Mesh, NFD, Nvidia GPU).
- KServeRaw deployment mode ([Reference](https://access.redhat.com/solutions/7078183)).
- TrustyAI component enabled.
- Rust installed in the machine that will run the tests agains the cluster ([Reference](https://www.rust-lang.org/tools/install)).

### Running the tests
This repo has two main components:
- A bash script to easily deploy an LLM (vLLM+KServeRaw), an arbitrary number of copies of a given detector model, and a configured GuardrailsOrchestrator (with gateway).
- A utility for running load test scenarios and generating reports, based on [Goose](https://book.goose.rs/).

In order to run the tests:
