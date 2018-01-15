CREATE TABLE [dbo].[CVO_promotions]
(
[promo_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_start_date] [datetime] NULL,
[promo_end_date] [datetime] NULL,
[commission] [decimal] (6, 4) NULL,
[order_discount] [decimal] (6, 2) NULL,
[payment_terms] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rebate_start_date] [datetime] NULL,
[rebate_end_date] [datetime] NULL,
[rebate_discount_per] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rebate_discount_amt] [decimal] (6, 4) NULL,
[rebate_credit] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[free_shipping] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[list] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[commissionable] [smallint] NULL,
[order_type] [smallint] NULL,
[frequency] [int] NULL,
[review_ship_to] [smallint] NULL,
[subscription] [smallint] NULL,
[designation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[promo_designation_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ignore_for_credit_pricing] [smallint] NULL,
[shipping_method] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subscription_designation_code_primary_only] [smallint] NULL,
[promo_designation_code_primary_only] [smallint] NULL,
[debit_promo] [smallint] NULL,
[debit_promo_percentage] [decimal] (5, 2) NULL,
[debit_promo_amount] [decimal] (20, 8) NULL,
[drawdown_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drawdown_level] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[drawdown_promo] [smallint] NULL,
[drawdown_expiry_days] [int] NULL,
[frequency_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hold_reason] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[annual_program] [smallint] NULL,
[season_program] [smallint] NULL,
[backorder_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_discount_amount] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[trg_cvo_promotions_ins_upd]
ON [dbo].[CVO_promotions]
FOR INSERT, UPDATE
AS

BEGIN
    DECLARE @what_updated VARCHAR(2048),
            @today DATETIME;

    SELECT @what_updated = '',
           @today = GETDATE();

    SELECT @what_updated
        = CASE
              WHEN d.promo_id IS NULL THEN
                  '|New Insert'
              ELSE
                  CASE
                      WHEN ISNULL(i.promo_name, '') <> ISNULL(d.promo_name, '') THEN
                          '|Promo_name, from: ' + ISNULL(d.promo_name, '') + ' to: ' + ISNULL(i.promo_name, '')
                      ELSE
                          ''
                  END
                  + CASE
                        WHEN ISNULL(i.promo_start_date, @today) <> ISNULL(d.promo_start_date, @today) THEN
                            '|Promo_start_date, from: ' + convert(VARCHAR(10),ISNULL(d.promo_start_date, @today),101) + ' to: '
                            + CONVERT(VARCHAR(10),ISNULL(i.promo_start_date, @today),101)
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.promo_end_date, @today) <> ISNULL(d.promo_end_date, @today) THEN
                            '|Promo_end_date, from: ' + CONVERT(varchar(10),ISNULL(d.promo_end_date, @today),101) + ' to: '
                            + CONVERT(varchar(10),ISNULL(i.promo_end_date, @today),101)
                        ELSE
                            ''
                    END + CASE
                              WHEN ISNULL(i.commission, 0) <> ISNULL(d.commission, 0) THEN
                                  '|Commission, from: ' + CAST(ISNULL(d.commission, 0) AS varchar(6)) + 
								  ' to: ' + CAST(ISNULL(i.commission, 0) AS varchar(6))
                              ELSE
                                  ''
                          END
                  + CASE
                        WHEN ISNULL(i.order_discount, 0) <> ISNULL(d.order_discount, 0) THEN
                            '|Order_discount, from: ' + CAST(ISNULL(d.order_discount, 0) AS varchar(6)) + ' to: '
                            + CAST(ISNULL(i.order_discount, 0) AS varchar(6))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.payment_terms, '') <> ISNULL(d.payment_terms, '') THEN
                            '|payment_terms, from: ' + ISNULL(d.payment_terms, '') + ' to: '
                            + ISNULL(i.payment_terms, '')
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.free_shipping, '') <> ISNULL(d.free_shipping, '') THEN
                            '|free_shipping, from: ' + ISNULL(d.free_shipping, '') + ' to: '
                            + ISNULL(i.free_shipping, '')
                        ELSE
                            ''
                    END + CASE
                              WHEN ISNULL(i.list, '') <> ISNULL(d.list, '') THEN
                                  '|list, from: ' + ISNULL(d.list, '') + ' to: ' + ISNULL(i.list, '')
                              ELSE
                                  ''
                          END + CASE
                                    WHEN ISNULL(i.cust, '') <> ISNULL(d.cust, '') THEN
                                        '|cust, from: ' + ISNULL(d.cust, '') + ' to: ' + ISNULL(i.cust, '')
                                    ELSE
                                        ''
                                END
                  + CASE
                        WHEN ISNULL(i.commissionable, 0) <> ISNULL(d.commissionable, 0) THEN
                            '|commissionable, from: ' + CAST(ISNULL(d.commissionable, 0) AS char(1)) + ' to: '
                            + CAST(ISNULL(i.commissionable, 0) AS CHAR(1))
                        ELSE
                            ''
                    END + CASE
                              WHEN ISNULL(i.order_type, 0) <> ISNULL(d.order_type, 0) THEN
                                  '|order_type, from: ' + CAST(ISNULL(d.order_type, 0) AS CHAR(1)) + 
								  ' to: ' + CAST(ISNULL(i.order_type, 0) AS CHAR(1))
                              ELSE
                                  ''
                          END
                  + CASE
                        WHEN ISNULL(i.frequency, 0) <> ISNULL(d.frequency, 0) THEN
                            '|frequency, from: ' + CAST(ISNULL(d.frequency, 0) AS CHAR(1)) + 
							' to: ' + CAST(ISNULL(i.frequency, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.review_ship_to, 0) <> ISNULL(d.review_ship_to, 0) THEN
                            '|review_ship_to, from: ' + CAST(ISNULL(d.review_ship_to, 0) AS CHAR(1)) + 
							' to: ' + CAST(ISNULL(i.review_ship_to, 0) AS CHAR(1))
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.shipping_method, '') <> ISNULL(d.shipping_method, '') THEN
                            '|shipping_method, from: ' + ISNULL(d.shipping_method, '') + ' to: '
                            + ISNULL(i.shipping_method, '')
                        ELSE
                            ''
                    END
                  + CASE
                        WHEN ISNULL(i.hold_reason, '') <> ISNULL(d.hold_reason, '') THEN
                            '|hold_reason, from: ' + ISNULL(d.hold_reason, '') + ' to: ' + ISNULL(i.hold_reason, '')
                        ELSE
                            ''
                    END
          END

    FROM inserted i
        LEFT JOIN deleted d
            ON i.promo_id = d.promo_id
               AND i.promo_level = d.promo_level;

    -- now insert into audit table

    INSERT INTO dbo.cvo_promotions_audit
	(promo_id, promo_level, action, what_updated, who_updated, when_updated, where_updated)
    SELECT I.promo_id,
           I.promo_level,
           CASE
               WHEN D.promo_id IS NULL THEN
                   'Insert'
               ELSE
                   'Update'
           END AS action,
           SUBSTRING(@what_updated,2,LEN(@what_updated)) What_updated,
           SUSER_SNAME() who_updated,
           GETDATE() when_updated,
		   'Header' where_updated

    FROM inserted I
        LEFT JOIN deleted D
            ON I.promo_id = D.promo_id
               AND I.promo_level = D.promo_level;

END;
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_promotions] ON [dbo].[CVO_promotions] ([promo_id], [promo_level]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_promotions] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_promotions] TO [public]
GO
