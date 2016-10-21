CREATE TABLE [dbo].[CVO_armaster_all]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coop_eligible] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coop_threshold_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coop_threshold_amount] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_armas__coop___76E5ABC5] DEFAULT ((0)),
[coop_dollars] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_armas__coop___77D9CFFE] DEFAULT ((0)),
[coop_notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coop_cust_rate_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[coop_cust_rate] [int] NULL,
[coop_dollars_prev_year] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_armas__coop___78CDF437] DEFAULT ((0)),
[coop_dollars_previous] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_armas__coop___79C21870] DEFAULT ((0)),
[rx_carrier] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bo_carrier] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[add_cases] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[add_patterns] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[max_dollars] [float] NULL CONSTRAINT [DF__CVO_armas__max_d__7AB63CA9] DEFAULT ((0)),
[metal_plastic] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_armas__metal__7BAA60E2] DEFAULT ('N'),
[suns_opticals] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_armas__suns___7C9E851B] DEFAULT ('N'),
[address_type] [smallint] NULL CONSTRAINT [DF__CVO_armas__addre__7D92A954] DEFAULT ((0)),
[consol_ship_flag] [int] NULL CONSTRAINT [DF__CVO_armas__conso__7E86CD8D] DEFAULT ((0)),
[coop_redeemed] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_armas__coop___7F7AF1C6] DEFAULT ((0)),
[allow_substitutes] [smallint] NULL,
[patterns_foo] [smallint] NULL,
[commissionable] [smallint] NULL,
[commission] [decimal] (5, 2) NULL,
[cvo_print_cm] [smallint] NULL CONSTRAINT [DF__CVO_armas__cvo_p__7BCA5C73] DEFAULT ((0)),
[cvo_chargebacks] [smallint] NULL CONSTRAINT [DF__CVO_armas__cvo_c__132459C5] DEFAULT ((1)),
[freight_charge] [smallint] NULL,
[ship_complete_flag_rx] [smallint] NULL CONSTRAINT [DF__CVO_armas__ship___73DCF1AD] DEFAULT ((0)),
[coop_ytd] [decimal] (20, 8) NULL,
[door] [smallint] NULL,
[credit_for_returns] [smallint] NULL,
[residential_address] [smallint] NULL,
[category_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[aging_check] [int] NULL CONSTRAINT [DF__CVO_armas__aging__2857DFFB] DEFAULT ((1)),
[aging_allowance] [float] NULL CONSTRAINT [DF__CVO_armas__aging__294C0434] DEFAULT ((0)),
[rx_consolidate] [smallint] NULL CONSTRAINT [DF__CVO_armas__rx_co__1260DF40] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:		cvo_armaster_all_upd_trg		
Type:		Trigger
Description:	Processes coop changes
Version:	1.0
Developer:	

History
-------
v1.1	CT	10/10/2012	Added logic to write coop changes to audit table
v1.2	CT	22/10/2012	Call recalculate routine when customer has coop switched off
v2.0	tag - get rid of coop updates and add commission update instead
select * From cvoarmasteraudit order by audit_date desc
v2.1 - add freight_charge changes to audit - per MS

update cvo_armaster_all set commission = isnull(commission,0) + 1.0 where
isnull(commissionable,0) = 1

update cvo_armaster_all set commissionable = 0 where
customer_code = '030774'


*/ 
  

CREATE TRIGGER [dbo].[cvo_armaster_all_upd_trg] ON [dbo].[CVO_armaster_all] 
FOR insert, UPDATE  
AS  
BEGIN  

INSERT CVOARMasterAudit (field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT  distinct 'commissionable'
, cast(d.commissionable as varchar(10))
, cast(i.commissionable as varchar(10))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code 
AND i.ship_to = d.ship_to -- 9/21/2016
AND i.address_type = d.address_type
where isnull(d.commissionable,0)<>isnull(i.commissionable,0)

INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'commission'
, cast (d.commission as varchar(20))
, cast (i.commission as varchar(20))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code 
AND i.ship_to = d.ship_to -- 9/21/2016
AND i.address_type = d.address_type
where isnull(d.commission,0)<>isnull(i.commission,0)

-- v2.1
INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'Freight Charge'
, cast (CASE d.freight_charge
			WHEN 1 THEN 'Cust Pays'
			WHEN 2 THEN 'Free BO'
			WHEN 3 THEN 'Free All'
			ELSE 'Unknown'
			end as VARCHAR(20))
, cast (CASE i.freight_charge
			WHEN 1 THEN 'Cust Pays'
			WHEN 2 THEN 'Free BO'
			WHEN 3 THEN 'Free All'
			ELSE 'Unknown'
			end as varchar(20))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code
AND i.ship_to = d.ship_to -- 9/21/2016 
AND i.address_type = d.address_type
where isnull(d.freight_charge,0)<>isnull(i.freight_charge,0)

-- 10/14/2016  - per LV request

INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'Back Order Flag RX'
, cast (CASE d.ship_complete_flag_rx
			WHEN 0 THEN 'Allow BO'
			WHEN 1 THEN 'Ship Comp'
			WHEN 2 THEN 'Partial Ship'
			ELSE 'Unknown'
			end as VARCHAR(20))
, cast (CASE i.ship_complete_flag_rx
			WHEN 0 THEN 'Allow BO'
			WHEN 1 THEN 'Ship Comp'
			WHEN 2 THEN 'Partial Ship'
			ELSE 'Unknown'
			end as varchar(20))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code
AND i.ship_to = d.ship_to -- 9/21/2016 
AND i.address_type = d.address_type
where isnull(d.ship_complete_flag_rx,0)<>isnull(i.ship_complete_flag_rx,0)

INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'RX Consolidate'
, cast (CASE d.rx_consolidate
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE 'Unknown'
			end as VARCHAR(20))
, cast (CASE i.rx_consolidate
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE 'Unknown'
			end as varchar(20))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code
AND i.ship_to = d.ship_to -- 9/21/2016 
AND i.address_type = d.address_type
where isnull(d.rx_consolidate,0)<>isnull(i.rx_consolidate,0)

INSERT CVOARMasterAudit 
(field_name
, field_from
, field_to
, customer_code
, ship_to_code
, movement_flag
, audit_date
, user_id) 
SELECT distinct 'Allow Substitutions'
, cast (CASE d.allow_substitutes
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE 'Unknown'
			end as VARCHAR(20))
, cast (CASE i.allow_substitutes
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE 'Unknown'
			end as varchar(20))
, i.customer_code
, i.ship_to
, 2 -- change
, getdate()
, SUSER_SNAME() 
from inserted i 
INNER JOIN deleted d ON 
i.customer_code = d.customer_code
AND i.ship_to = d.ship_to -- 9/21/2016 
AND i.address_type = d.address_type
where isnull(d.allow_substitutes,0)<>isnull(i.allow_substitutes,0)

END  
  
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_armaster_all] ON [dbo].[CVO_armaster_all] ([customer_code], [ship_to], [address_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_armaster_all] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_armaster_all] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_armaster_all] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_armaster_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_armaster_all] TO [public]
GO
