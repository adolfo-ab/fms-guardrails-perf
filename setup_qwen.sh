#!/bin/bash

set -e

NAMESPACE="test-namespace"
YAML_FILE="resources/qwen.yaml"

oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

oc apply -f "$YAML_FILE" -n "$NAMESPACE"

echo "Waiting for qwen InferenceService to be ready..."
oc wait --for=condition=Ready inferenceservice/qwen25 -n "$NAMESPACE" --timeout=600s

oc get inferenceservice qwen25 -n "$NAMESPACE"

echo "Checking pod status..."
oc get pods -n "$NAMESPACE" -l serving.kserve.io/inferenceservice=qwen25