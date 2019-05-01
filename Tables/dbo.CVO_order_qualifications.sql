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
[ff_max_free_sun] [smallint] NULL,
[combine] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__combi__75DF7056] DEFAULT ('N'),
[bogo_buy_qty] [int] NULL,
[bogo_get_qty] [int] NULL,
[bogo_gender_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__bogo___3140F89D] DEFAULT ('N'),
[bogo_attribute_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__bogo___32351CD6] DEFAULT ('N'),
[adt_get_discount] [decimal] (20, 8) NULL,
[adt_gender_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__adt_g__3329410F] DEFAULT ('N'),
[adt_attribute_check] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_order__adt_a__341D6548] DEFAULT ('N'),
[bogo_get_brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adt_brand] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bogo_get_discount] [decimal] (20, 8) NULL
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
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[trg_cvo_order_qualifications_ins_upd]
ON [dbo].[CVO_order_qualifications]
FOR INSERT, UPDATE
AS

BEGIN
    DECLARE @what_updated VARCHAR(2048),
            @today DATETIME;

    SELECT @what_updated = '',
           @today = GETDATE();

    SELECT @what_updated
        = CASE
              WHEN d.promo_ID IS NULL THEN
                  '|New Insert'
              ELSE
				  CASE
                            WHEN ISNULL(i.brand, '') <> ISNULL(d.brand, '') THEN
                                '|brand, from: ' + ISNULL(d.brand,'') + ' to: ' + ISNULL(i.brand,'')
                            ELSE
                                ''
                        END 
				+ CASE
                                  WHEN ISNULL(i.category, '') <> ISNULL(d.category, '') THEN
                                      '|category, from: ' + ISNULL(d.category,'') + ' to: ' + ISNULL(i.category,'')
                                  ELSE
                                      ''
                              END
                  + CASE
                        WHEN ISNULL(i.min_qty, 0) <> ISNULL(d.min_qty, 0) THEN
                            '|min_qty, from: ' + CAST(ISNULL(d.min_qty, 0) AS VARCHAR(6)) + ' to: '
                            + CAST(ISNULL(i.min_qty, 0) AS VARCHAR(6))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.max_qty, 0) <> ISNULL(d.max_qty, 0) THEN
                            '|max_qty, from: ' + CAST(ISNULL(d.max_qty, 0) AS VARCHAR(6)) + ' to: '
                            + CAST(ISNULL(i.max_qty, 0) AS VARCHAR(6))
                        ELSE
                            ''
                    END + CASE
                              WHEN ISNULL(i.two_colors, '') <> ISNULL(d.two_colors, '') THEN
                                  '|two_colors, from: ' + ISNULL(d.two_colors, '') + ' to: ' + ISNULL(i.two_colors, '')
                              ELSE
                                  ''
                          END + CASE
                                    WHEN ISNULL(i.and_, '') <> ISNULL(d.and_, '') THEN
                                        '|and_, from: ' + ISNULL(d.and_, '') + ' to: ' + ISNULL(i.and_, '')
                                    ELSE
                                        ''
                                END + CASE
                                          WHEN ISNULL(i.or_, '') <> ISNULL(d.or_, '') THEN
                                              '|or_, from: ' + ISNULL(d.or_, '') + ' to: ' + ISNULL(i.or_, '')
                                          ELSE
                                              ''
                                      END
                  + CASE
                        WHEN ISNULL(i.gender, '') <> ISNULL(d.gender, '') THEN
                            '|gender, from: ' + ISNULL(d.gender, '') + ' to: ' + ISNULL(i.gender, '')
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.brand_exclude, '') <> ISNULL(d.brand_exclude, '') THEN
                            '|brand_exclude, from: ' + ISNULL(d.brand_exclude, '') + ' to: '
                            + ISNULL(i.brand_exclude, '')
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.category_exclude, '') <> ISNULL(d.category_exclude, '') THEN
                            '|category_exclude, from: ' + ISNULL(d.category_exclude, '') + ' to: '
                            + ISNULL(i.category_exclude, '')
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.min_sales, 0) <> ISNULL(d.min_sales, 0) THEN
                            '|min_sales, from: ' + CAST(ISNULL(d.min_sales, 0) AS VARCHAR(12)) + ' to: '
                            + CAST(ISNULL(i.min_sales, 0) AS VARCHAR(12))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.max_sales, 0) <> ISNULL(d.max_sales, 0) THEN
                            '|max_sales, from: ' + CAST(ISNULL(d.max_sales, 0) AS VARCHAR(12)) + ' to: '
                            + CAST(ISNULL(i.max_sales, 0) AS VARCHAR(12))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.attribute, 0) <> ISNULL(d.attribute, 0) THEN
                            '|attribute, from: ' + CAST(ISNULL(d.attribute, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.attribute, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.gender_check, 0) <> ISNULL(d.gender_check, 0) THEN
                            '|gender_check, from: ' + CAST(ISNULL(d.gender_check, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.gender_check, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.free_frames, 0) <> ISNULL(d.free_frames, 0) THEN
                            '|free_frames, from: ' + CAST(ISNULL(d.free_frames, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.free_frames, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_min_qty, 0) <> ISNULL(d.ff_min_qty, 0) THEN
                            '|ff_min_qty, from: ' + CAST(ISNULL(d.ff_min_qty, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_min_qty, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_min_frame, 0) <> ISNULL(d.ff_min_frame, 0) THEN
                            '|ff_min_frame, from: ' + CAST(ISNULL(d.ff_min_frame, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_min_frame, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_min_sun, 0) <> ISNULL(d.ff_min_sun, 0) THEN
                            '|ff_min_sun, from: ' + CAST(ISNULL(d.ff_min_sun, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_min_sun, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_max_free_qty, 0) <> ISNULL(d.ff_max_free_qty, 0) THEN
                            '|ff_max_free_qty, from: ' + CAST(ISNULL(d.ff_max_free_qty, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_max_free_qty, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_max_free_frame, 0) <> ISNULL(d.ff_max_free_frame, 0) THEN
                            '|ff_max_free_frame, from: ' + CAST(ISNULL(d.ff_max_free_frame, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_max_free_frame, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.ff_max_free_sun, 0) <> ISNULL(d.ff_max_free_sun, 0) THEN
                            '|ff_max_free_sun, from: ' + CAST(ISNULL(d.ff_max_free_sun, 0) AS CHAR(1)) + ' to: '
                            + CAST(ISNULL(i.ff_max_free_sun, 0) AS CHAR(1))
                        ELSE
                            ''
                    END + CASE
                              WHEN ISNULL(i.combine, '') <> ISNULL(d.combine, '') THEN
                                  '|combine, from: ' + ISNULL(d.combine, '') + ' to: ' + ISNULL(i.combine, '')
                              ELSE
                                  ''
                          END
          END

    FROM inserted i
        LEFT JOIN deleted d
            ON i.promo_ID = d.promo_ID
               AND i.promo_level = d.promo_level
			   AND i.line_no = d.line_no;

    -- now insert into audit table

    INSERT INTO dbo.cvo_promotions_audit
    (
        promo_id,
        promo_level,
        action,
        what_updated,
        who_updated,
        when_updated,
		where_updated
    )
    SELECT I.promo_ID,
           I.promo_level,
           CASE
               WHEN D.promo_ID IS NULL THEN
                   'Insert'
               ELSE
                   'Update'
           END AS action,
           SUBSTRING(@what_updated, 2, LEN(@what_updated)) What_updated,
           SUSER_SNAME() who_updated,
           GETDATE() when_updated,
		   'OrderQual' where_updated

    FROM inserted I
        LEFT JOIN deleted D
            ON I.promo_ID = D.promo_ID
               AND I.promo_level = D.promo_level;

END;

-- SELECT * FROM cvo_promotions_audit

-- UPDATE dbo.CVO_order_qualifications SET min_Qty = 16 WHERE promo_ID = 'sunps' AND promo_level = '1' AND line_no = '1'
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_order_qualifications] ON [dbo].[CVO_order_qualifications] ([promo_ID], [line_no], [promo_level]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_order_qualifications] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_order_qualifications] TO [public]
GO
