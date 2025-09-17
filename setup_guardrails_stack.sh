#!/bin/bash

set -e

NAMESPACE="test-namespace"
QWEN_YAML="resources/qwen.yaml"
DETECTOR_YAML="resources/detector_model.yaml"
GORCH_YAML="resources/fms-gorch.yaml"

oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

oc apply -f "$DETECTOR_YAML" -n "$NAMESPACE"
oc apply -f "$QWEN_YAML" -n "$NAMESPACE"
oc apply -f "$GORCH_YAML" -n "$NAMESPACE"

oc wait --for=condition=Ready inferenceservice/ibm-hate-and-profanity-detector -n "$NAMESPACE" --timeout=600s
oc wait --for=condition=Ready inferenceservice/qwen25 -n "$NAMESPACE" --timeout=600s

oc get inferenceservice -n "$NAMESPACE"
oc get guardrailsorchestrator -n "$NAMESPACE"
oc get pods -n "$NAMESPACE"