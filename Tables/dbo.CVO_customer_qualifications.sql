CREATE TABLE [dbo].[CVO_customer_qualifications]
(
[promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand_include] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category_include] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_sales] [decimal] (8, 2) NULL,
[max_sales] [decimal] (8, 2) NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL,
[past_promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[past_promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_rx_per] [decimal] (8, 2) NULL,
[max_rx_per] [decimal] (8, 2) NULL,
[return_per] [decimal] (8, 2) NULL,
[and_] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_custom__and___7038AE36] DEFAULT ('N'),
[or_] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_custome__or___712CD26F] DEFAULT ('N'),
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [brand_exclude_default] DEFAULT ('N'),
[category_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [category_exclude_default] DEFAULT ('N'),
[gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[no_of_pieces] [decimal] (20, 8) NULL,
[order_type] [smallint] NULL,
[attribute] [smallint] NULL,
[gender_check] [smallint] NULL,
[max_no_of_pieces] [decimal] (20, 8) NULL,
[pp_not_purchased] [smallint] NULL,
[rolling_period] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			cvo_customer_qualifications_del_trg		
Type:			Trigger
Description:	Removes attributes for the deleted line
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	06/02/2013	Original Version
v1.1	CT	12/02/2013	Clear gender records
*/


CREATE TRIGGER [dbo].[cvo_customer_qualifications_del_trg] ON [dbo].[CVO_customer_qualifications]
FOR DELETE
AS
BEGIN
	DECLARE	@promo_id		VARCHAR(20),
			@promo_level	VARCHAR(30),
			@line_no		INT,
			@row_id			INT


	-- Create temporary table to hold deleted lines
	CREATE TABLE #deleted (
		row_id		INT IDENTITY (1,1),
		promo_id	VARCHAR(20),
		promo_level	VARCHAR(30),
		line_no		INT)

	-- Load deleted records into temp table
	INSERT #deleted(
		promo_id,
		promo_level,
		line_no)
	SELECT
		promo_id,
		promo_level,
		line_no
	FROM
		deleted
	
	IF NOT EXISTS (SELECT 1 FROM #deleted)
		RETURN	

	SET @row_id = 0
		
	-- Get the line to action
	WHILE 1=1
	BEGIN
	
		SELECT TOP 1 
			@row_id = row_id,
			@promo_id = promo_id,
			@promo_level = promo_level,
			@line_no = line_no
		FROM 
			#deleted 
		WHERE
			row_id > @row_id
		ORDER BY 
			row_id

		IF @@ROWCOUNT = 0
			Break

		-- Delete attribute record
		DELETE FROM
			dbo.cvo_promotions_attribute
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level
			AND line_no = @line_no
			AND line_type = 'C'

		-- Delete order type record
		DELETE FROM
			dbo.cvo_promotions_cust_order_type
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level
			AND line_no = @line_no

		-- START v1.1
		-- Delete gender record
		DELETE FROM
			dbo.cvo_promotions_gender
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level
			AND line_no = @line_no
			AND line_type = 'C'
		-- END v1.1
	END			
END


GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_customer_qualifications] ON [dbo].[CVO_customer_qualifications] ([promo_ID], [line_no], [promo_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_customer_qualifications] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_customer_qualifications] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_customer_qualifications] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_customer_qualifications] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_customer_qualifications] TO [public]
GO
