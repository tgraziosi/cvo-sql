CREATE TABLE [dbo].[cvo_cust_salesperson]
(
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[salesperson_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[primary_rep] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___prima__6C96C895] DEFAULT ('N'),
[include_rx] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___inclu__6D8AECCE] DEFAULT ('N'),
[split] [decimal] (20, 8) NULL CONSTRAINT [DF__cvo_cust___split__6E7F1107] DEFAULT ((0.0)),
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___brand__6F733540] DEFAULT (''),
[brand_split] [decimal] (20, 8) NULL CONSTRAINT [DF__cvo_cust___brand__70675979] DEFAULT ((0.0)),
[brand_excl] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___brand__715B7DB2] DEFAULT ('N'),
[comm_rate] [decimal] (20, 8) NULL,
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___brand__79F0C3B3] DEFAULT ('N'),
[promo_id] [varchar] (31) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___promo__7AE4E7EC] DEFAULT (''),
[rx_only] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_cust___rx_on__7BD90C25] DEFAULT ('N'),
[startdate] [datetime] NULL,
[enddate] [datetime] NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[cvo_cust_salesperson_audit_tr]
ON [dbo].[cvo_cust_salesperson]
FOR INSERT, UPDATE, DELETE
AS
BEGIN

	-- INSERTS
	INSERT	cvo_cust_salesperson_audit (row_type, audit_date, user_spid, username, customer_code, salesperson_code, 
		primary_rep, include_rx, split, brand, brand_split, brand_excl, comm_rate, brand_exclude, promo_id, rx_only, 
		startdate, enddate, ship_to)
	SELECT	'INSERT', GETDATE(), @@SPID, suser_sname(), a.customer_code, a.salesperson_code, a.primary_rep, a.include_rx, a.split, a.brand, 
			a.brand_split, a.brand_excl, a.comm_rate, a.brand_exclude, a.promo_id, a.rx_only, a.startdate, a.enddate, a.ship_to
	FROM	inserted a
	LEFT JOIN deleted b
	ON		a.customer_code = b.customer_code
	AND		a.salesperson_code = b.salesperson_code
	WHERE	b.customer_code IS NULL
	AND		b.salesperson_code IS NULL

	-- UPDATE	
	INSERT	cvo_cust_salesperson_audit (row_type, audit_date, user_spid, username, customer_code, salesperson_code, 
		primary_rep, include_rx, split, brand, brand_split, brand_excl, comm_rate, brand_exclude, promo_id, rx_only, 
		startdate, enddate, ship_to)
	SELECT	'BEFORE UPDATE', GETDATE(), @@SPID, suser_sname(), a.customer_code, a.salesperson_code, a.primary_rep, a.include_rx, a.split, a.brand, 
			a.brand_split, a.brand_excl, a.comm_rate, a.brand_exclude, a.promo_id, a.rx_only, a.startdate, a.enddate, a.ship_to
	FROM	deleted a
	JOIN	inserted b
	ON		a.customer_code = b.customer_code
	AND		a.salesperson_code = b.salesperson_code

	INSERT	cvo_cust_salesperson_audit (row_type, audit_date, user_spid, username, customer_code, salesperson_code, 
		primary_rep, include_rx, split, brand, brand_split, brand_excl, comm_rate, brand_exclude, promo_id, rx_only, 
		startdate, enddate, ship_to)
	SELECT	'AFTER UPDATE', GETDATE(), @@SPID, suser_sname(), a.customer_code, a.salesperson_code, a.primary_rep, a.include_rx, a.split, a.brand, 
			a.brand_split, a.brand_excl, a.comm_rate, a.brand_exclude, a.promo_id, a.rx_only, a.startdate, a.enddate, a.ship_to
	FROM	inserted a
	JOIN	deleted b
	ON		a.customer_code = b.customer_code
	AND		a.salesperson_code = b.salesperson_code

	-- DELETES
	INSERT	cvo_cust_salesperson_audit (row_type, audit_date, user_spid, username, customer_code, salesperson_code, 
		primary_rep, include_rx, split, brand, brand_split, brand_excl, comm_rate, brand_exclude, promo_id, rx_only, 
		startdate, enddate, ship_to)
	SELECT	'DELETE', GETDATE(), @@SPID, suser_sname(), a.customer_code, a.salesperson_code, a.primary_rep, a.include_rx, a.split, a.brand, 
			a.brand_split, a.brand_excl, a.comm_rate, a.brand_exclude, a.promo_id, a.rx_only, a.startdate, a.enddate, a.ship_to
	FROM	deleted a
	LEFT JOIN inserted b
	ON		a.customer_code = b.customer_code
	AND		a.salesperson_code = b.salesperson_code
	WHERE	b.customer_code IS NULL
	AND		b.salesperson_code IS NULL

END
GO
CREATE NONCLUSTERED INDEX [cvo_cust_salesperson_ind0] ON [dbo].[cvo_cust_salesperson] ([customer_code]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_cust_salesperson] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cust_salesperson] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cust_salesperson] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cust_salesperson] TO [public]
GO
