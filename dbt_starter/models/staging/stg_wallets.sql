-- Staging model for wallets.
-- No duplicate wallet_id found in the raw source (verified during exploration),
-- so this is mainly type casting and standardizing nulls. member_id and
-- marketing_channel are expected to contain nulls per the data dictionary.

with source as (

    select * from {{ source('raw', 'raw_wallets') }}

),

renamed as (

    select
        wallet_id,
        nullif(member_id, '')          as member_id,
        country,
        onboarding_method,
        nullif(marketing_channel, '')  as marketing_channel,
        status,
        cast(created_at as timestamp)  as created_at
    from source

)

select * from renamed
