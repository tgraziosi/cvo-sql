CREATE TABLE [dbo].[CVO_ord_list]
(
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[add_case] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__add_c__5D25D9C2] DEFAULT ('N'),
[add_pattern] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__add_p__5E19FDFB] DEFAULT ('N'),
[from_line_no] [int] NULL,
[is_case] [int] NULL CONSTRAINT [DF__CVO_ord_l__is_ca__5F0E2234] DEFAULT ((0)),
[is_pattern] [int] NULL CONSTRAINT [DF__CVO_ord_l__is_pa__6002466D] DEFAULT ((0)),
[add_polarized] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__add_p__60F66AA6] DEFAULT ('N'),
[is_polarized] [int] NULL CONSTRAINT [DF__CVO_ord_l__is_po__61EA8EDF] DEFAULT ((0)),
[is_pop_gif] [int] NULL CONSTRAINT [DF__CVO_ord_l__is_po__62DEB318] DEFAULT ((0)),
[is_amt_disc] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__is_am__63D2D751] DEFAULT ('N'),
[amt_disc] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_ord_l__amt_d__64C6FB8A] DEFAULT ((0)),
[is_customized] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__is_cu__65BB1FC3] DEFAULT ('N'),
[promo_item] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__CVO_ord_l__promo__66AF43FC] DEFAULT ('N'),
[list_price] [decimal] (20, 8) NULL CONSTRAINT [DF__CVO_ord_l__list___67A36835] DEFAULT ((0)),
[orig_list_price] [decimal] (20, 8) NULL,
[free_frame] [smallint] NULL,
[due_date] [datetime] NULL,
[upsell_flag] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Trigger CVO_ord_list_kit_trg    Script Date: 12/01/2010  ***** 
Object:      Trigger  CVO_ord_list_kit_trg  
Source file: CVO_ord_list_kit_trg.sql
Author:		 Craig Boston
Created:	 12/02/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
select * from cvo_ord_list_kit where order_no = 1282
v1.0 CB 23/07/2012	Buying group list price change
v1.1 CB 29/05/2013 Temp fix for orphaned cvo_ord_list records
v1.2 CB 29/10/2015 Fix issue with list price on promo kits
TAG - 10/2018 - write tdc_log for upsell activities
*/

CREATE TRIGGER [dbo].[CVO_ord_list_trg]
ON [dbo].[CVO_ord_list]
for INSERT, UPDATE
AS
BEGIN


    UPDATE a
    SET orig_list_price = d.price,
        list_price = CASE
                         WHEN a.promo_item = 'Y' THEN
                             d.price
                         ELSE
                             a.list_price
                     END -- v1.2
    FROM CVO_ord_list a
        JOIN inserted i
            ON a.order_no = i.order_no
               AND a.order_ext = i.order_ext
               AND a.line_no = i.line_no
        JOIN ord_list b (NOLOCK)
            ON a.order_no = b.order_no
               AND a.order_ext = b.order_ext
               AND a.line_no = b.line_no
        JOIN adm_inv_price c (NOLOCK)
            ON b.part_no = c.part_no
        JOIN adm_inv_price_det d (NOLOCK)
            ON c.inv_price_id = d.inv_price_id
    WHERE c.active_ind = 1;


    -- v1.1 Start
    DELETE a
    FROM CVO_ord_list a
        JOIN inserted b
            ON a.order_no = b.order_no
               AND a.order_ext = b.order_ext
        LEFT JOIN ord_list c (NOLOCK)
            ON a.order_no = c.order_no
               AND a.order_ext = c.order_ext
               AND a.line_no = c.line_no
    WHERE c.line_no IS NULL;
    -- v1.1 End

    -- capture upsell to tdc_log 10/2018

    DECLARE @order_no INT, @ext INT, @line_no INT, @i_upsell_flag INT, @d_upsell_flag int

    SELECT @order_no = i.order_no,
           @ext = i.order_ext,
           @line_no = i.line_no,
           @i_upsell_flag = i.upsell_flag,
           @d_upsell_flag = d.upsell_flag
           FROM inserted i
           LEFT OUTER JOIN deleted d ON d.order_no = i.order_no AND d.order_ext = i.order_ext AND d.line_no = i.line_no

     IF (@i_upsell_flag <> 0 AND @d_upsell_flag IS NULL) OR @i_upsell_flag <> ISNULL(@d_upsell_flag,0)
     begin

    INSERT INTO tdc_log 
    (
        tran_date,
        UserID,
        trans_source,
        module,
        trans,
        tran_no,
        tran_ext,
        part_no,
        lot_ser,
        bin_no,
        location,
        quantity,
        data
    )
    SELECT GETDATE(),
           SYSTEM_USER,
           'BO',
           'SALES ORDER',
           CASE
               WHEN @i_upsell_flag = 1 THEN
                   'UPSELL ON'
               WHEN @i_upsell_flag = 0 THEN
                   'UPSELL OFF'
               ELSE
                   'UPSELL'
           END,
           @order_no,
           @ext,
           OL.part_no,
           '',
           '',
           '',
           OL.ordered * CASE WHEN @i_upsell_flag = 0 THEN -1 ELSE 1 END ,
           'UPSELL FLAG CHANGE'
    FROM cvo_ord_list col (nolock)
        JOIN ord_list OL (NOLOCK)
            ON OL.order_no = col.order_no
               AND OL.order_ext = col.order_ext
               AND OL.line_no = col.line_no
        JOIN orders o (nolock)
                ON o.order_no = col.order_no AND o.ext = col.order_ext
    WHERE col.order_no = @order_no AND col.order_ext = @ext AND col.line_no = @line_no
            AND o.type = 'i'
            ;
    END;

END;

-- UPDATE cvo_ord_list SET upsell_flag = 1 WHERE order_no = 3476735
GO
CREATE NONCLUSTERED INDEX [cvo_ord_list_ind0] ON [dbo].[CVO_ord_list] ([order_no], [order_ext], [is_customized]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [idx_CVO_ord_list] ON [dbo].[CVO_ord_list] ([order_no], [order_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [cvo_ord_list_upsell_idx] ON [dbo].[CVO_ord_list] ([upsell_flag]) INCLUDE ([amt_disc], [line_no], [list_price], [order_ext], [order_no]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[CVO_ord_list] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ord_list] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_ord_list] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ord_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ord_list] TO [public]
GO
