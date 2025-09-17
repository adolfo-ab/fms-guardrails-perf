use goose::prelude::*;

const TEST_PROMPT: &str = "What is the opposite of up?";

async fn loadtest_inference(user: &mut GooseUser) -> TransactionResult {
    let token = std::env::var("TOKEN")
        .unwrap_or_else(|_| "TOKEN environment variable not set".to_string());
    let scenario = std::env::var("SCENARIO")
        .unwrap_or_else(|_| "SCENARIO environment variable not set".to_string());

    match scenario.as_str() {
        "baseline" => {
            let payload = serde_json::json!({
                "model": "qwen25",
                "messages": [{"role": "user", "content": TEST_PROMPT}],
                "temperature": 0
            });

            let reqwest_request_builder = user
                .get_request_builder(&GooseMethod::Post, "/v1/chat/completions")?
                .header("Content-Type", "application/json")
                .bearer_auth(token)
                .json(&payload);

            let goose_request = GooseRequest::builder()
                .set_request_builder(reqwest_request_builder)
                .build();

            user.request(goose_request).await?;
        }
        "guardrails" => {
            let payload = serde_json::json!({
                "model": "qwen25",
                "messages": [{"role": "user", "content": TEST_PROMPT}],
                "temperature": 0
            });

            let reqwest_request_builder = user
                .get_request_builder(&GooseMethod::Post, "/all/v1/chat/completions")?
                .header("Content-Type", "application/json")
                .bearer_auth(token)
                .json(&payload);

            let goose_request = GooseRequest::builder()
                .set_request_builder(reqwest_request_builder)
                .build();

            user.request(goose_request).await?;
        }
        _ => {
            eprintln!("Invalid scenario '{}', must be 'baseline' or 'guardrails'", scenario);
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<(), GooseError> {
    GooseAttack::initialize()?
        .register_scenario(
            scenario!("LoadTestModels").register_transaction(transaction!(loadtest_inference)),
        )
        .execute()
        .await?;

    Ok(())
}