-- Staging model for merchants. Cleanest of the three raw sources: no duplicate
-- merchant_id, no unexpected nulls. Just type/rename standardization.

with source as (

    select * from {{ source('raw', 'raw_merchants') }}

),

renamed as (

    select
        merchant_id,
        merchant_name,
        mcc,
        segment,
        country,
        cast(onboarded_at as timestamp) as onboarded_at
    from source

)

select * from renamed
