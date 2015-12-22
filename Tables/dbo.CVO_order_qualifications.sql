CREATE TABLE [dbo].[CVO_order_qualifications]
(
[promo_ID] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[line_no] [int] NOT NULL,
[brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[category] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[min_qty] [int] NULL,
[max_qty] [int] NULL,
[two_colors] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__two_c__355648DC] DEFAULT ('N'),
[and_] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order___and___364A6D15] DEFAULT ('N'),
[or_] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order_q__or___373E914E] DEFAULT ('N'),
[gender] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[brand_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [orq_brand_exclude_default] DEFAULT ('N'),
[category_exclude] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [orq_category_exclude_default] DEFAULT ('N'),
[min_sales] [decimal] (20, 8) NULL,
[max_sales] [decimal] (20, 8) NULL,
[attribute] [smallint] NULL,
[gender_check] [smallint] NULL,
[free_frames] [smallint] NULL,
[ff_min_qty] [int] NULL,
[ff_min_frame] [smallint] NULL,
[ff_min_sun] [smallint] NULL,
[ff_max_free_qty] [int] NULL,
[ff_max_free_frame] [smallint] NULL,
[ff_max_free_sun] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Name:			cvo_order_qualifications_del_trg		
Type:			Trigger
Description:	Removes attributes for the deleted line
Version:		1.0
Developer:		Chris Tyler

History
-------
v1.0	CT	06/02/2013	Original Version
v1.1	CT	12/02/2013	Clear gender records
*/


CREATE TRIGGER [dbo].[cvo_order_qualifications_del_trg] ON [dbo].[CVO_order_qualifications]
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
			AND line_type = 'O'

		-- START v1.1
		-- Delete gender record
		DELETE FROM
			dbo.cvo_promotions_gender
		WHERE
			promo_id = @promo_id
			AND promo_level = @promo_level
			AND line_no = @line_no
			AND line_type = 'O'
		-- END v1.1

	END			
END


GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_order_qualifications] ON [dbo].[CVO_order_qualifications] ([promo_ID], [line_no], [promo_level]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_order_qualifications] TO [public]
GO
