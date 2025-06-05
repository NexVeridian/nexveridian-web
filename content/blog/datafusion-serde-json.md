+++
title = "Using `serde_json` or `serde` data, in `datafusion`"
date = 2025-06-05

[taxonomies]
tags = ["datafusion", "serde", "serde_json","dataframe"]
+++

Getting data into [`datafusion`](https://github.com/apache/datafusion) is not well documented, especially using `serde_json` or `serde` data.

This example shows how to convert a `serde_json::Value::Array` into a `datafusion` `DataFrame`, manipulate the `dataframe` in `datafusion`, then convert it back to `serde_json`.

```toml
# Cargo.toml
datafusion = "47.0.0"
serde_arrow = { version = "0.13.3", features = ["arrow-55"] }
```

```rust
// `serde_json::Value`
let json = serde_json::json!([{
    "date": "2025-06-05",
    "test": "test",
    "price": 1.01,
}]);

let ctx = SessionContext::new();

let serde_json::Value::Array(json_array) = &json else {
    return Err(anyhow::anyhow!("Expected JSON array, got different type"));
};

if json_array.is_empty() {
    return Ok(Vec::new());
}

// Configure `TracingOptions` to allow null fields and coerce numbers
let tracing_options = TracingOptions::default()
    .allow_null_fields(true)
    .coerce_numbers(true);

// Get the schema from actual data, using samples, with `TracingOptions`
let fields = Vec::<FieldRef>::from_samples(json_array, tracing_options)?;

// Convert `serde_json::Value::Array` to `RecordBatch` using `serde_arrow`
let record_batch = serde_arrow::to_record_batch(&fields, &json_array)?;

// Create a DataFrame from the `RecordBatch`
let mut df = ctx.read_batch(record_batch)?;

// Add a new column `new_col` using DataFrame API
df = df.with_column("new_col", lit("test".to_string()))?;

// Execute the DataFrame query
let result_batches = df.collect().await?;

// Convert back to `serde_json` using `serde_arrow`
let all_json_values = result_batches
    .into_iter()
    .flat_map(|batch| {
        serde_arrow::from_record_batch(&batch).unwrap_or_else(|_| Vec::new())
    })
    .collect::<Vec<serde_json::Value>>();

#[derive(Default, Debug, Clone, Deserialize, Serialize)]
pub struct TestData {
    date: String,
    test: String,
    price: f64,
    new_col: String,
}

// Convert the `serde_json::Value` to Vec<TestData>
let test_data: Vec<TestData> =
    serde_json::from_value(serde_json::Value::Array(all_json_values))?;

assert_eq!(
    test_data,
    Vec![
        TestData {
            date: "2025-06-05".to_string(),
            test: "test".to_string(),
            price: 1.01,
            new_col: "test".to_string(),
        },
    ]
);
```

# Or you use can use this `datafusion_ext`
```rust
// src/utils/datafusion_ext.rs
use anyhow::Error;
use datafusion::{arrow::datatypes::FieldRef, dataframe::DataFrame, prelude::*};
use serde_arrow::schema::{SchemaLike, TracingOptions};

pub trait JsonValueExt {
    /// Converts a `serde_json::Value::Array` into a `datafusion::dataframe`
    fn to_df(&self) -> Result<DataFrame, Error>;
}

impl JsonValueExt for serde_json::Value {
    fn to_df(&self) -> Result<DataFrame, Error> {
        let ctx = SessionContext::new();

        let Self::Array(json_array) = self else {
            return Err(anyhow::anyhow!(
                "Expected `serde_json::Value::Array`, got different type"
            ));
        };

        if json_array.is_empty() {
            return Err(anyhow::anyhow!("Empty `serde_json::Value::Array` provided"));
        }

        let tracing_options = TracingOptions::default()
            .allow_null_fields(true)
            .coerce_numbers(true);

        let fields = Vec::<FieldRef>::from_samples(json_array, tracing_options)?;
        let record_batch = serde_arrow::to_record_batch(&fields, &json_array)?;

        let df = ctx.read_batch(record_batch)?;

        Ok(df)
    }
}

#[async_trait::async_trait]
pub trait DataFrameExt {
    /// Collects a `datafusion::dataframe` and deserializes it to a Vec of the
    /// specified type
    async fn to_vec<T>(&self) -> Result<Vec<T>, Error>
    where
        T: serde::de::DeserializeOwned;
}

#[async_trait::async_trait]
impl DataFrameExt for DataFrame {
    async fn to_vec<T>(&self) -> Result<Vec<T>, Error>
    where
        T: serde::de::DeserializeOwned,
    {
        let result_batches = self.clone().collect().await?;

        let all_json_values = result_batches
            .into_iter()
            .flat_map(|batch| serde_arrow::from_record_batch(&batch).unwrap_or_else(|_| Vec::new()))
            .collect::<Vec<serde_json::Value>>();

        let typed_result: Vec<T> =
            serde_json::from_value(serde_json::Value::Array(all_json_values))?;

        Ok(typed_result)
    }
}
```

```rust
use utils::datafusion_ext::{DataFrameExt, JsonValueExt};

let json = serde_json::json!([{
    "date": "2025-06-05",
    "test": "test",
    "price": 1.01,
}]);

let mut df = json.to_df()?;

df = df.with_column("new_col", lit("test".to_string()))?;

#[derive(Default, Debug, Clone, Deserialize, Serialize)]
pub struct TestData {
    date: String,
    test: String,
    price: f64,
    new_col: String,
}

let etfs = df.to_vec::<TestData>().await?;

assert_eq!(
    test_data,
    Vec![
        TestData {
            date: "2025-06-05".to_string(),
            test: "test".to_string(),
            price: 1.01,
            new_col: "test".to_string(),
        },
    ]
);
```
