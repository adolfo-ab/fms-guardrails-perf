#!/bin/bash

set -e

NAMESPACE="test-namespace"
QWEN_YAML="resources/qwen.yaml"
MODEL_STORAGE_YAML="resources/model_storage.yaml"
DETECTOR_SR_YAML="resources/detector_model.yaml"
DETECTOR_TEMPLATE="resources/detector_inference_template.yaml"
GORCH_YAML="resources/fms-gorch.yaml"

# Number of detector instances to deploy
NUM_DETECTORS=1
BASE_DETECTOR_NAME="ibm-hate-and-profanity-detector"

oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

oc apply -f "$MODEL_STORAGE_YAML" -n "$NAMESPACE"
oc wait --for=condition=Available deployment/model-s3-storage-emulator -n "$NAMESPACE" --timeout=600s

oc apply -f "$DETECTOR_SR_YAML" -n "$NAMESPACE"

# Create multiple detector InferenceServices
for i in $(seq 1 $NUM_DETECTORS); do
    DETECTOR_NAME="${BASE_DETECTOR_NAME}-${i}"

    # Create a temporary YAML file with the detector name substituted
    TEMP_DETECTOR="/tmp/detector_${i}.yaml"
    sed "s/DETECTOR_NAME/$DETECTOR_NAME/g" "$DETECTOR_TEMPLATE" > "$TEMP_DETECTOR"

    oc apply -f "$TEMP_DETECTOR" -n "$NAMESPACE"

    # Clean up temp file
    rm "$TEMP_DETECTOR"
done

oc apply -f "$QWEN_YAML" -n "$NAMESPACE"
oc apply -f "$GORCH_YAML" -n "$NAMESPACE"

# Wait for all detector instances to be ready
for i in $(seq 1 $NUM_DETECTORS); do
    DETECTOR_NAME="${BASE_DETECTOR_NAME}-${i}"
    oc wait --for=condition=Ready inferenceservice/$DETECTOR_NAME -n "$NAMESPACE" --timeout=600s
done

oc wait --for=condition=Ready inferenceservice/qwen25 -n "$NAMESPACE" --timeout=600s

oc get inferenceservice -n "$NAMESPACE"
oc get guardrailsorchestrator -n "$NAMESPACE"
oc get pods -n "$NAMESPACE"