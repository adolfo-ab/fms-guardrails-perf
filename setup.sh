#!/bin/bash

set -e

# Default values
DEFAULT_NUM_DETECTORS=3
DEFAULT_DETECTOR_NAME="jailbreak-detector"
DEFAULT_DETECTOR_MODEL="jailbreak-classifier"
DEFAULT_MODEL_TO_DOWNLOAD="jackhhao/jailbreak-classifier"

# Parse command line arguments
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --num-detectors NUM    Number of detector instances to deploy (default: $DEFAULT_NUM_DETECTORS)"
    echo "  -d, --detector-name NAME   Base name for detector instances (default: $DEFAULT_DETECTOR_NAME)"
    echo "  -m, --model-path PATH      Model path for detector (default: $DEFAULT_DETECTOR_MODEL)"
    echo "  -D, --download-model MODEL Model to download from HuggingFace (default: $DEFAULT_MODEL_TO_DOWNLOAD)"
    echo "  -h, --help                 Show this help message"
    exit 1
}

NUM_DETECTORS=$DEFAULT_NUM_DETECTORS
BASE_DETECTOR_NAME=$DEFAULT_DETECTOR_NAME
DETECTOR_MODEL=$DEFAULT_DETECTOR_MODEL
MODEL_TO_DOWNLOAD=$DEFAULT_MODEL_TO_DOWNLOAD

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--num-detectors)
            NUM_DETECTORS="$2"
            shift 2
            ;;
        -d|--detector-name)
            BASE_DETECTOR_NAME="$2"
            shift 2
            ;;
        -m|--model-path)
            DETECTOR_MODEL="$2"
            shift 2
            ;;
        -D|--download-model)
            MODEL_TO_DOWNLOAD="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option $1"
            usage
            ;;
    esac
done

# Validate inputs
if ! [[ "$NUM_DETECTORS" =~ ^[0-9]+$ ]] || [ "$NUM_DETECTORS" -lt 1 ]; then
    echo "Error: Number of detectors must be a positive integer"
    exit 1
fi

NAMESPACE="test-namespace"
QWEN_YAML="resources/qwen.yaml"
MODEL_STORAGE_TEMPLATE="resources/model_storage_template.yaml"
DETECTOR_SR_YAML="resources/detector_model.yaml"
DETECTOR_TEMPLATE="resources/detector_inference_template.yaml"
GORCH_YAML="resources/fms-gorch.yaml"

echo "Deploying $NUM_DETECTORS detector instances using model '$DETECTOR_MODEL'"

oc create namespace "$NAMESPACE" --dry-run=client -o yaml | oc apply -f -

# Create model storage with the specified model to download
TEMP_MODEL_STORAGE="/tmp/model_storage.yaml"
sed "s|MODEL_TO_DOWNLOAD|$MODEL_TO_DOWNLOAD|g" "$MODEL_STORAGE_TEMPLATE" > "$TEMP_MODEL_STORAGE"
oc apply -f "$TEMP_MODEL_STORAGE" -n "$NAMESPACE"
rm "$TEMP_MODEL_STORAGE"

oc wait --for=condition=Available deployment/model-s3-storage -n "$NAMESPACE" --timeout=600s

oc apply -f "$DETECTOR_SR_YAML" -n "$NAMESPACE"

# Create multiple detector InferenceServices
for i in $(seq 1 $NUM_DETECTORS); do
    DETECTOR_NAME="${BASE_DETECTOR_NAME}-${i}"

    # Create a temporary YAML file with the detector name and model substituted
    TEMP_DETECTOR="/tmp/detector_${i}.yaml"
    sed -e "s/DETECTOR_NAME/$DETECTOR_NAME/g" -e "s/DETECTOR_MODEL/$DETECTOR_MODEL/g" "$DETECTOR_TEMPLATE" > "$TEMP_DETECTOR"

    oc apply -f "$TEMP_DETECTOR" -n "$NAMESPACE"

    # Clean up temp file
    rm "$TEMP_DETECTOR"
done

oc apply -f "$QWEN_YAML" -n "$NAMESPACE"

# Wait for all detector instances to be ready
for i in $(seq 1 $NUM_DETECTORS); do
    DETECTOR_NAME="${BASE_DETECTOR_NAME}-${i}"
    oc wait --for=condition=Ready inferenceservice/$DETECTOR_NAME -n "$NAMESPACE" --timeout=600s
done

oc wait --for=condition=Ready inferenceservice/qwen25 -n "$NAMESPACE" --timeout=600s

sleep 30
oc apply -f "$GORCH_YAML" -n "$NAMESPACE"
