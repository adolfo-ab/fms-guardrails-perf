use goose::prelude::*;

async fn loadtest_inference(user: &mut GooseUser) -> Result<(), GooseError> {
    let token =
        std::env::var("TOKEN").unwrap_or_else(|_| "TOKEN environment variable not set".to_string());
    let scenario = std::env::var("SCENARIO")
        .unwrap_or_else(|_| "SCENARIO environment variable not set".to_string());

    match scenario.as_str() {
        "baseline" => {
            let _goose_metrics = user
                .get_request_builder(&GooseMethod::Get, "/v1/models")?
                .header("Authorization", token)
                .send()
                .await?;
            return Ok(());
        }
        "guardrails" => {
            let _goose_metrics = user
                .get_request_builder(&GooseMethod::Get, "/v1/models")?
                .header("Authorization", token)
                .send()
                .await?;
            return Ok(());
        }
        _ => {
            return Err(GooseError::from(
                "Invalid scenario, must be 'baseline' or 'guardrails'",
            ));
        }
    };
}

#[tokio::main]
async fn main() -> Result<(), GooseError> {
    GooseAttack::initialize()?
        .register_scenario(
            scenario!("LoadTestModels").register_transaction(transaction!(loadtest_models)),
        )
        .execute()
        .await?;

    Ok(())
}
