SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC CVO_CHARGEBACKS_SP "cutoff date = 737084 and create_doc = 'N'"
-- prod version


CREATE PROCEDURE [dbo].[cvo_chargebacks_sp] @where_clause VARCHAR(255)
AS
--
-- v4.0	TM	04/16/2012 - Remove any lines where the discount comes out negative
-- v5.0 TM  05/19/2012 - Remove any customer that has a past due balance < 0
-- v6.0 TM  06/09/2012 - Do not pick up invoices already on chargebacks
-- v6.1 TG 07/27/2012 - fix where conditions - add isnull on promo id, and = cutoffdate to not pick up older invoices
-- v6.2.1 tg 09/2012  & 10/2012 - changes to fineline what chargebacks are made - include credit details
-- v6.3 tg - dont allow chargebacks on debit promo activity
-- v6.4 - tg - fix discount pricing logic to pick up is_amt_disc orders correctly
-- SELECT dbo.adm_get_pltdate_f('01/25/2019')


DECLARE @cutoff_date INT,
        @Create_doc VARCHAR(1);

SET NOCOUNT ON;

DECLARE @debug INT;
SELECT @debug = 0;

-- DECLARE @where_clause VARCHAR(255);

SELECT @cutoff_date = CONVERT(INT, SUBSTRING(@where_clause, CHARINDEX('=', @where_clause) + 1, 7));
SELECT @Create_doc = ISNULL(UPPER(SUBSTRING(@where_clause, CHARINDEX('%', @where_clause) + 1, 1)), 'N');
--

--select @cutoff_date = 737084
--select @create_doc = 'N'


DECLARE @Total_of_invoice DECIMAL(20, 8),
        @days_due INT,
        @date_due INT,
        @id_no INT,
        @customer_code VARCHAR(8),
        @disc_cback FLOAT,
        @ErrFlag INT,
        @terms_code VARCHAR(10);

IF
(
    SELECT OBJECT_ID('tempdb..#Temp')
) IS NOT NULL
    DROP TABLE #Temp;
IF
(
    SELECT OBJECT_ID('tempdb..#Temp_inv')
) IS NOT NULL
    DROP TABLE #Temp_inv;
IF
(
    SELECT OBJECT_ID('tempdb..#tmp_custbal')
) IS NOT NULL
    DROP TABLE #tmp_custbal;
IF
(
    SELECT OBJECT_ID('tempdb..#tmP_custbal_open')
) IS NOT NULL
    DROP TABLE #tmP_custbal_open;
IF
(
    SELECT OBJECT_ID('tempdb..#tmp_bgbal')
) IS NOT NULL
    DROP TABLE #tmp_bgbal;
IF
(
    SELECT OBJECT_ID('tempdb..#tmp_bgbal_open')
) IS NOT NULL
    DROP TABLE #tmp_bgbal_open;
IF
(
    SELECT OBJECT_ID('tempdb..#temp_pp')
) IS NOT NULL
    DROP TABLE #temp_pp;
IF
(
    SELECT OBJECT_ID('tempdb..#temp_cr')
) IS NOT NULL
    DROP TABLE #temp_cr;
IF
(
    SELECT OBJECT_ID('tempdb..#temp_cash')
) IS NOT NULL
    DROP TABLE #temp_cash;

CREATE TABLE #Temp
(
    id_no INT IDENTITY(1, 1),
    customer_code VARCHAR(16),
    cust_name VARCHAR(40),
    doc_ctrl_num VARCHAR(16),
    trx_ctrl_num VARCHAR(16),
    date_due INT,
    shipped FLOAT,
    invoice_unit FLOAT,
    list_unit FLOAT,
    disc_given FLOAT,
    disc_pct FLOAT,
    disc_nochg FLOAT,
    why VARCHAR(3),
    order_ctrl_num VARCHAR(16),
    part_no VARCHAR(30),
    bg_code VARCHAR(16),
    trx_type SMALLINT
);

CREATE INDEX #temp_idx1 ON #Temp (customer_code, doc_ctrl_num);
CREATE TABLE #Temp_inv
(
    id_no INT IDENTITY(1, 1),
    customer_code VARCHAR(16),
    cust_name VARCHAR(40),
    doc_ctrl_num VARCHAR(16),
    trx_ctrl_num VARCHAR(16),
    date_due INT,
    shipped FLOAT,
    invoice_unit FLOAT,
    list_unit FLOAT,
    disc_given FLOAT,
    disc_pct FLOAT,
    disc_nochg FLOAT,
    why VARCHAR(3),
    order_ctrl_num VARCHAR(16),
    part_no VARCHAR(30),
    bg_code VARCHAR(16),
    trx_type SMALLINT
);

IF (OBJECT_ID('tempdb..#Tmp_bgbal') IS NOT NULL)
    DROP TABLE #Tmp_bgbal;
CREATE TABLE #tmp_bgbal
(
    bg_code VARCHAR(8),
    cust_code VARCHAR(8),
    shipto_code VARCHAR(8),
    doc_ctrl_no VARCHAR(16),
    open_amount DECIMAL(20, 2),
    --v6.2
    trx_type SMALLINT
);
CREATE INDEX #temp_idx1 ON #tmp_bgbal (cust_code, doc_ctrl_no);


INSERT INTO #Temp
(
    customer_code,
    cust_name,
    doc_ctrl_num,
    trx_ctrl_num,
    date_due,
    shipped,
    invoice_unit,
    list_unit,
    disc_given,
    disc_pct,
    disc_nochg,
    why,
    order_ctrl_num,
    part_no,
    bg_code,
    trx_type
)
-- invoices
SELECT ar.customer_code,
       ac.customer_name,
       ar.doc_ctrl_num,
       oi.trx_ctrl_num,
       ar.date_due,
       ol.shipped,
       ROUND((ol.curr_price - ROUND(cl.amt_disc, 2)), 2, 1) AS sell_price,
       cl.list_price AS list_price,
       CASE
           WHEN ISNULL(cl.is_amt_disc, '') = 'Y' THEN
               ROUND(ISNULL(cl.amt_disc, 0), 2)
           ELSE
               round(cl.list_price*p.disc_perc, 2)
       END * ol.shipped AS total_discount,
       CONVERT(DECIMAL(10, 4), p.disc_perc) AS disc_pct,
       0 AS disc_nochg,
       '',
       ar.order_ctrl_num,
       ol.part_no,
       -- dbo.f_cvo_get_buying_group(ar.customer_code, GETDATE()) AS bg_code,
       ISNULL(
       (
           SELECT TOP 1 parent FROM arnarel WHERE ar.customer_code = child
       ),
       ''
             ) AS bg_code,
       ar.trx_type
FROM orders_invoice oi (NOLOCK)
    LEFT JOIN orders_all oh (NOLOCK)
        ON oi.order_no = oh.order_no
           AND oi.order_ext = oh.ext --v2.0
    LEFT JOIN CVO_orders_all ch (NOLOCK)
        ON oi.order_no = ch.order_no
           AND oi.order_ext = ch.ext --v3.0
    LEFT JOIN ord_list ol (NOLOCK)
        ON oi.order_no = ol.order_no
           AND oi.order_ext = ol.order_ext
    LEFT JOIN CVO_ord_list cl (NOLOCK)
        ON ol.order_no = cl.order_no
           AND ol.order_ext = cl.order_ext
           AND ol.line_no = cl.line_no
    LEFT JOIN dbo.CVO_disc_percent AS p
        ON p.order_no = ol.order_no
           AND p.order_ext = ol.order_ext
           AND p.line_no = ol.line_no
    LEFT JOIN inv_master iv (NOLOCK)
        ON ol.part_no = iv.part_no
    LEFT JOIN artrx ar (NOLOCK)
        ON oi.trx_ctrl_num = ar.trx_ctrl_num
           AND ar.trx_type = 2031
           AND ar.paid_flag = 0
    LEFT JOIN arcust ac (NOLOCK)
        ON ar.customer_code = ac.customer_code
    LEFT JOIN CVO_armaster_all cm (NOLOCK)
        ON ar.customer_code = cm.customer_code
           AND cm.address_type = 0
WHERE ol.price <> cl.list_price
      AND ol.shipped > 0
      AND oh.user_category NOT IN ( 'ST-CL' ) --v2.0
      AND ISNULL(ch.promo_id, '') NOT IN ( 'QOP', 'EOR', 'EOS', 'EAG' ) --v3.0 - v6.1 - tag - 072612
      AND ar.paid_flag = 0
      AND ar.doc_ctrl_num > ''
      AND iv.type_code IN ( 'FRAME', 'SUN' )
      AND ISNULL(cm.cvo_chargebacks, 1) = 1
      AND ar.date_due = @cutoff_date -- v6.1 - change from <= to =
      AND SUBSTRING(ar.doc_ctrl_num, 1, 2) NOT IN ( 'FC', 'CB' )
      AND NOT EXISTS
(
    SELECT 1
    FROM artrxcdt cdt
    WHERE cdt.doc_ctrl_num LIKE 'CB%'
          AND ar.doc_ctrl_num = SUBSTRING(cdt.line_desc, 1, 10)
)

      --ar.doc_ctrl_num NOT IN
      --    (
      --SELECT DISTINCT
      --       SUBSTRING(line_desc, 1, 10), line_desc, *
      --FROM artrxcdt
      --WHERE doc_ctrl_num LIKE 'CB%'
      --    ) --v6.0
      -- v6.3 - 031814 debit promos cant be charged back
      AND NOT EXISTS
(
    SELECT 1
    FROM CVO_debit_promo_customer_det dd
    WHERE dd.order_no = oi.order_no
          AND dd.ext = oi.order_ext
);
--v4.0
--select * from #temp WHERE (disc_given < 0 and trx_type = 2031) or (disc_given > 0 and trx_type = 2032)

-- SELECT * FROM #Temp AS t ORDER BY t.id_no

IF @debug = 0
    DELETE #Temp
    WHERE (
              disc_given < 0
              AND trx_type = 2031
          )
          OR
          (
              disc_given > 0
              AND trx_type = 2032
          );

-- Test a buying group


--
-- GATHER DETAIL for buying groups
--
INSERT INTO #tmp_bgbal
-- Invoices
SELECT arn.parent,
       h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       CONVERT(DECIMAL(20, 2), h.amt_net - h.amt_paid_to_date) AS Open_Amount,
       h.trx_type -- v6.2
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
    INNER JOIN arnarel arn (NOLOCK)
        ON h.customer_code = arn.child
WHERE a.trx_type = 2031
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      --v6.2
      --and a.date_due = @cutoff_date -- v6.1 - chage from <= to =
      AND a.date_due >= @cutoff_date -- v6.1 - chage from <= to =
--v6.2

UNION
-- OA Cash Receipts
SELECT arn.parent,
       h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       h.amt_on_acct * -1,
       a.trx_type
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
    INNER JOIN arnarel arn (NOLOCK)
        ON h.customer_code = arn.child
WHERE a.trx_type = 2111
      AND h.trx_type <> 2112
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      AND h.amt_on_acct > 0
UNION
-- OA Credit Memos
SELECT arn.parent,
       h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       ROUND((h.amt_on_acct * -1), 2),
       a.trx_type
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
    INNER JOIN arnarel arn (NOLOCK)
        ON h.customer_code = arn.child
WHERE a.trx_type = 2161
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      AND ROUND(h.amt_on_acct, 2) > 0
      -- v6.3 - dont include debit memo activity
      AND NOT EXISTS
(
    SELECT 1
    FROM CVO_debit_promo_customer_det dd
    WHERE dd.trx_ctrl_num = h.trx_ctrl_num
)
ORDER BY h.customer_code,
         h.ship_to_code;


--
IF (OBJECT_ID('tempdb..#tmp_bgBal_Open') IS NOT NULL)
    DROP TABLE #tmp_bgBal_Open;

CREATE TABLE #tmp_bgBal_Open
(
    bg_code VARCHAR(8),
    open_amount DECIMAL(20, 2)
);
--
-- SUMMARIZE TOTAL OPEN BY buying group
--
INSERT INTO #tmp_bgBal_Open
SELECT bg_code,
       SUM(open_amount)
FROM #tmp_bgbal
GROUP BY bg_code
ORDER BY bg_code;
--

-- select * FROM #tmp_bgBal_Open WHERE open_amount > 0
IF @debug = 0
    DELETE FROM #tmp_bgBal_Open
    WHERE open_amount > 0;

--select * from #temp where bg_code in (select bg_code from #tmp_bgBal_Open)

IF @debug = 0
    DELETE FROM #Temp
    WHERE bg_code IN
          (
              SELECT bg_code FROM #tmp_bgBal_Open
          );

-------

-- Determine if a Customer has a net balance < $0 - for direct customers
--

IF (OBJECT_ID('tempdb..#tmp_CustBal') IS NOT NULL)
    DROP TABLE #tmp_CustBal;

CREATE TABLE #tmp_CustBal
(
    cust_code VARCHAR(8),
    shipto_code VARCHAR(8),
    doc_ctrl_no VARCHAR(16),
    open_amount DECIMAL(20, 2),
    --v6.2
    trx_type SMALLINT
);

CREATE INDEX #temp_idx1 ON #tmp_CustBal (cust_code, doc_ctrl_no);

--
-- GATHER DETAIL for Direct Customers
--
INSERT INTO #tmp_CustBal
-- Invoices
SELECT h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       CONVERT(DECIMAL(20, 2), h.amt_net - h.amt_paid_to_date) AS Open_Amount,
       h.trx_type -- v6.2
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
WHERE a.trx_type = 2031
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      AND NOT EXISTS
(
    SELECT * FROM arnarel (NOLOCK) WHERE h.customer_code = child
)
      --v6.2
      --and a.date_due = @cutoff_date -- v6.1 - chage from <= to =
      AND a.date_due >= @cutoff_date -- v6.1 - chage from <= to =
--v6.2

UNION
-- OA Cash Receipts
SELECT h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       h.amt_on_acct * -1,
       a.trx_type
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
WHERE a.trx_type = 2111
      AND h.trx_type <> 2112
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      AND h.amt_on_acct > 0
      AND NOT EXISTS
(
    SELECT * FROM arnarel (NOLOCK) WHERE h.customer_code = child
)
UNION
-- OA Credit Memos
SELECT h.customer_code,
       h.ship_to_code,
       h.doc_ctrl_num,
       ROUND((h.amt_on_acct * -1), 2),
       a.trx_type
FROM armaster b (NOLOCK),
     arcust c (NOLOCK),
     artrxage a (NOLOCK)
    INNER JOIN artrx h (NOLOCK)
        ON a.trx_ctrl_num = h.trx_ctrl_num
WHERE a.trx_type = 2161
      AND h.customer_code = c.customer_code
      AND h.customer_code = b.customer_code
      AND h.ship_to_code = b.ship_to_code
      AND a.paid_flag = 0
      AND b.status_type = 1
      AND ROUND(h.amt_on_acct, 2) > 0
      AND NOT EXISTS
(
    SELECT * FROM arnarel (NOLOCK) WHERE h.customer_code = child
)
ORDER BY h.customer_code,
         h.ship_to_code;

--
IF (OBJECT_ID('tempdb..#tmp_CustBal_Open') IS NOT NULL)
    DROP TABLE #tmp_CustBal_Open;
CREATE TABLE #tmp_CustBal_Open
(
    cust_code VARCHAR(8),
    open_amount DECIMAL(20, 2)
);
--
-- SUMMARIZE TOTAL OPEN BY CUSTOMER/SHIP TO
--
INSERT INTO #tmp_CustBal_Open
SELECT cust_code,
       SUM(open_amount)
FROM #tmp_CustBal
GROUP BY cust_code
ORDER BY cust_code;
--
IF @debug = 0
    DELETE FROM #tmp_CustBal_Open
    WHERE open_amount > 0;

--select * from #temp where customer_code in (select cust_code from #tmp_custBal_Open)

IF @debug = 0
    DELETE FROM #Temp
    WHERE customer_code IN
          (
              SELECT cust_code FROM #tmp_CustBal_Open
          );
--
--

-- v5.0 BEGIN

IF (OBJECT_ID('tempdb..#past_due_bal') IS NOT NULL)
    DROP TABLE #past_due_bal;

CREATE TABLE #past_due_bal
(
    amount FLOAT,
    on_acct FLOAT,
    age_b1 FLOAT,
    age_b2 FLOAT,
    age_b3 FLOAT,
    age_b4 FLOAT,
    age_b5 FLOAT,
    age_b6 FLOAT,
    home_curr VARCHAR(8),
    age_b0 FLOAT
);

DECLARE @Net_past_due FLOAT;


SELECT @customer_code = MIN(customer_code)
FROM #Temp;
WHILE @customer_code IS NOT NULL
BEGIN
    INSERT #past_due_bal
    EXEC cc_summary_aging_sp @customer_code, '4', 0, 'CVO', 'CVO';
    SELECT @Net_past_due = age_b2 + age_b3 + age_b4 + age_b5 + age_b6
    FROM #past_due_bal;
    IF @Net_past_due <= 0
    BEGIN
        DELETE FROM #Temp
        WHERE customer_code = @customer_code; -- If Past Due < 0 Then remove
    --select 'DELETED '+@customer_code
    END;
    TRUNCATE TABLE #past_due_bal; -- Clear dat out
    SELECT @customer_code = MIN(customer_code)
    FROM #Temp
    WHERE customer_code > @customer_code;
END;


DELETE t
FROM #Temp t
    JOIN
    (
        SELECT DISTINCT
               customer_code
        FROM #Temp
        GROUP BY customer_code
        HAVING (SUM(disc_given) <= 0)
    ) neg
        ON t.customer_code = neg.customer_code;

-- select * from #temp
-- Credit details were loaded along with invoices.  Clear out any that are no longer open.

--delete from #temp where not exists 
--	(select * from #tmp_custbal t2 where customer_code = t2.cust_code
--	and #temp.doc_ctrl_num = t2.doc_ctrl_no and t2.trx_type = 2161)
--	and trx_type = 2032

DECLARE @last_trx VARCHAR(16);
DECLARE @pp_amt FLOAT;
DECLARE @id SMALLINT;
DECLARE @last_cust VARCHAR(12);
DECLARE @last_cust_cr VARCHAR(12);
DECLARE @credit_amt FLOAT;
DECLARE @disc FLOAT;
DECLARE @NET_amt FLOAT;

-- Reduce chgeback amount by amt paid on partially paid invoice
IF
(
    SELECT OBJECT_ID('tempdb..#Temp_pp')
) IS NOT NULL
    DROP TABLE #Temp_pp;

CREATE TABLE #Temp_pp
(
    id_no INT IDENTITY(1, 1),
    customer_code VARCHAR(16),
    trx_ctrl_num VARCHAR(16),
    amt_paid_to_date FLOAT
);

INSERT INTO #Temp_pp
SELECT DISTINCT
       t1.customer_code,
       t1.trx_ctrl_num,
       amt_paid_to_date
FROM #Temp t1,
     artrx ar (NOLOCK)
WHERE t1.trx_ctrl_num = ar.trx_ctrl_num
      AND t1.trx_type = 2031
      AND ar.amt_paid_to_date <> 0;
SET @last_trx = '';
SET @pp_amt = 0;
DELETE #Temp_inv;


SELECT @last_trx = MIN(trx_ctrl_num)
FROM #Temp_pp;

WHILE @last_trx IS NOT NULL
BEGIN
    SELECT @pp_amt = amt_paid_to_date
    FROM #Temp_pp
    WHERE trx_ctrl_num = @last_trx;
    DELETE #Temp_inv;
    INSERT INTO #Temp_inv
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           why,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp
    WHERE trx_ctrl_num = @last_trx
          AND why = ''
    ORDER BY doc_ctrl_num,
             disc_pct;
    DELETE FROM #Temp
    WHERE trx_ctrl_num = @last_trx
          AND why = '';

    SELECT @id = MIN(id_no)
    FROM #Temp_inv;

    WHILE @pp_amt >=
    (
        SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
    )
          AND @id IS NOT NULL
    BEGIN
        UPDATE #Temp_inv
        SET disc_nochg = disc_given
        WHERE id_no = @id;
        SET @pp_amt = @pp_amt -
                      (
                          SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
                      );
        SELECT @id = MIN(id_no)
        FROM #Temp_inv
        WHERE id_no > @id;
    END;
    INSERT INTO #Temp
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           CASE
               WHEN disc_nochg <> 0 THEN
                   'PPI'
               ELSE
                   why
           END,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp_inv;
    DELETE #Temp_inv;

    SELECT @last_trx = MIN(trx_ctrl_num)
    FROM #Temp_pp
    WHERE trx_ctrl_num > @last_trx;
END; -- pp loop

-- Use up on account Cash according to discount %

IF (OBJECT_ID('tempdb..#Temp_cash') IS NOT NULL)
    DROP TABLE #Temp_cash;

CREATE TABLE #Temp_cash
(
    id_no INT IDENTITY(1, 1),
    customer_code VARCHAR(16),
    open_amount FLOAT
);

INSERT INTO #Temp_cash
SELECT cust_code,
       SUM(ABS(open_amount)) open_amount
FROM #tmp_CustBal
WHERE trx_type = 2111
GROUP BY cust_code
ORDER BY cust_code;
SET @last_cust = '';
SELECT @last_cust = MIN(customer_code)
FROM #Temp_cash;
DELETE #Temp_inv;
SET @credit_amt = 0;

WHILE @last_cust IS NOT NULL
BEGIN
    SELECT @credit_amt = ABS(SUM(open_amount))
    FROM #Temp_cash
    WHERE @last_cust = customer_code;
    DELETE #Temp_inv;
    INSERT INTO #Temp_inv
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           why,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp
    WHERE customer_code = @last_cust
          AND why = ''
    ORDER BY doc_ctrl_num,
             disc_pct,
             invoice_unit;

    DELETE #Temp
    WHERE customer_code = @last_cust
          AND why = '';

    SELECT @id = MIN(id_no)
    FROM #Temp_inv;
    WHILE @credit_amt >=
    (
        SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
    )
          AND @id IS NOT NULL
    BEGIN
        UPDATE #Temp_inv
        SET disc_nochg = disc_given
        WHERE id_no = @id;
        SET @credit_amt = @credit_amt -
                          (
                              SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
                          );
        SELECT @id = MIN(id_no)
        FROM #Temp_inv
        WHERE id_no > @id;
    END;
    INSERT INTO #Temp
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           CASE
               WHEN disc_nochg <> 0 THEN
                   'OA$'
               ELSE
                   why
           END,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp_inv;

    DELETE #Temp_inv;

    SELECT @last_cust = MIN(customer_code)
    FROM #Temp_cash
    WHERE customer_code > @last_cust;
END; -- loop for cash


-- Use up on account credits according to discount %

IF
(
    SELECT OBJECT_ID('tempdb..#Temp_cr')
) IS NOT NULL
    DROP TABLE #Temp_cr;

CREATE TABLE #Temp_cr
(
    id_no INT IDENTITY(1, 1),
    customer_code VARCHAR(16),
    open_amount FLOAT
);

INSERT INTO #Temp_cr
SELECT cust_code,
       SUM(ABS(open_amount))
FROM #tmp_CustBal
WHERE trx_type = 2161
GROUP BY cust_code
ORDER BY cust_code;
SET @last_cust = '';
SELECT @last_cust = MIN(customer_code)
FROM #Temp_cr;
DELETE #Temp_inv;
SET @credit_amt = 0;

WHILE @last_cust IS NOT NULL
BEGIN
    SELECT @credit_amt = SUM(ABS(open_amount))
    FROM #Temp_cr
    WHERE @last_cust = customer_code;
    DELETE #Temp_inv;
    INSERT INTO #Temp_inv
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           why,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp
    WHERE customer_code = @last_cust
          AND trx_type = 2031
          AND why = ''
    ORDER BY doc_ctrl_num,
             disc_pct,
             invoice_unit;

    DELETE FROM #Temp
    WHERE customer_code = @last_cust
          AND why = '';

    SELECT @id = MIN(id_no)
    FROM #Temp_inv;
    WHILE @credit_amt >=
    (
        SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
    )
          AND @id IS NOT NULL
    BEGIN
        UPDATE #Temp_inv
        SET disc_nochg = disc_given
        WHERE id_no = @id;
        SET @credit_amt = @credit_amt -
                          (
                              SELECT invoice_unit * shipped FROM #Temp_inv WHERE id_no = @id
                          );
        SELECT @id = MIN(id_no)
        FROM #Temp_inv
        WHERE id_no > @id;
    END;
    INSERT INTO #Temp
    (
        customer_code,
        cust_name,
        doc_ctrl_num,
        trx_ctrl_num,
        date_due,
        shipped,
        invoice_unit,
        list_unit,
        disc_given,
        disc_pct,
        disc_nochg,
        why,
        order_ctrl_num,
        part_no,
        bg_code,
        trx_type
    )
    SELECT customer_code,
           cust_name,
           doc_ctrl_num,
           trx_ctrl_num,
           date_due,
           shipped,
           invoice_unit,
           list_unit,
           disc_given,
           disc_pct,
           disc_nochg,
           CASE
               WHEN disc_nochg <> 0 THEN
                   'OAC'
               ELSE
                   why
           END,
           order_ctrl_num,
           part_no,
           bg_code,
           trx_type
    FROM #Temp_inv;
    DELETE #Temp_inv;

    SELECT @last_cust = MIN(customer_code)
    FROM #Temp_cr
    WHERE customer_code > @last_cust;
END; -- cm loop


--DECLARE pdcb CURSOR FOR
--SELECT DISTINCT
--       customer_code
--FROM #Temp
--WHERE trx_type = 2031
--GROUP BY customer_code
--HAVING (SUM(disc_given - disc_nochg) <= 0)
--ORDER BY customer_code;
--OPEN pdcb;
--FETCH NEXT FROM pdcb
--INTO @customer_code;
--WHILE (@@fetch_status = 0)
--BEGIN
--    DELETE FROM #Temp
--    WHERE customer_code = @customer_code;
--    FETCH NEXT FROM pdcb
--    INTO @customer_code;
--END;
--CLOSE pdcb;
--DEALLOCATE pdcb;

WITH pdcb
AS (SELECT DISTINCT
           customer_code
    FROM #Temp T
    WHERE trx_type = 2031
    GROUP BY customer_code
    HAVING (SUM(disc_given - disc_nochg) <= 0))
DELETE t
FROM #Temp t
    JOIN pdcb
        ON t.customer_code = pdcb.customer_code;

-- done with selections

IF @Create_doc = 'Y'
BEGIN

    CREATE TABLE #TempSum
    (
        id_no INT IDENTITY(1, 1),
        customer_code VARCHAR(16),
        disc_CBack FLOAT
    );

    INSERT INTO #TempSum
    (
        customer_code,
        disc_CBack
    )
    SELECT customer_code,
           SUM(disc_given - disc_nochg)
    FROM #Temp
    GROUP BY customer_code
    ORDER BY customer_code;

    DECLARE ap01 CURSOR FOR
    SELECT id_no,
           customer_code,
           disc_CBack
    FROM #TempSum
    ORDER BY id_no;

    OPEN ap01;
    FETCH NEXT FROM ap01
    INTO @id_no,
         @customer_code,
         @disc_cback;
    WHILE (@@fetch_status = 0)
    BEGIN

        BEGIN TRANSACTION;

        --Get the doc_ctrl_num      
        DECLARE @doc_ctrl_number_inv VARCHAR(10);
        SELECT @doc_ctrl_number_inv = SUBSTRING(   mask,
                                                   1,
                                                   10 -
        (
            SELECT LEN(next_num) FROM ewnumber WHERE num_type = 3004
        )
                                               ) + CAST(next_num AS VARCHAR(16))
        FROM ewnumber
        WHERE num_type = 3004;

        --Get the next trx_ctrl_num      
        UPDATE ewnumber
        SET next_num = next_num + 1
        WHERE num_type = 3004;

        --trx_ctrl_num   
        DECLARE @control_number_inv VARCHAR(16),
                @num INT;
        EXEC ARGetNextControl_SP 2000, @control_number_inv OUTPUT, @num OUTPUT;

        COMMIT TRANSACTION;


        SELECT @terms_code = terms_code
        FROM arcust
        WHERE customer_code = @customer_code;

        EXEC dbo.CVO_CalcDueDate_sp @customer_code,
                                    @cutoff_date,
                                    @date_due OUTPUT,
                                    @terms_code;

        ---------------------------------------------------------    
        -- Begin Creation Process
        ---------------------------------------------------------    

        CREATE TABLE #TempDet
        (
            lne_id INT IDENTITY(1, 1),
            customer_code VARCHAR(16),
            doc_ctrl_num VARCHAR(16),
            order_ctrl_num VARCHAR(16),
            disc_given FLOAT
        );

        INSERT INTO #TempDet
        (
            customer_code,
            doc_ctrl_num,
            order_ctrl_num,
            disc_given
        )
        SELECT customer_code,
               doc_ctrl_num,
               order_ctrl_num,
               disc_given - disc_nochg
        FROM #Temp
        WHERE customer_code = @customer_code;

        SELECT @ErrFlag = 0;

        BEGIN TRANSACTION;

        ---------------------------------------------------------    
        /*arinpchg_all*/
        ---------------------------------------------------------    

        INSERT INTO arinpchg_all
        SELECT NULL AS timestamp,
               @control_number_inv AS trx_ctrl_num,
               @doc_ctrl_number_inv,
               'ChargeBack Invoice' AS doc_desc,
               ' ' AS apply_to_num,
               0 AS apply_trx_type,
               ' ' AS order_ctrl_num,
               '' AS batch_code,
               2031 AS trx_type,
               @cutoff_date AS date_entered,
               @cutoff_date AS date_applied,
               @cutoff_date AS date_doc,
               @cutoff_date AS date_shipped,
               @cutoff_date AS date_required,
               @date_due AS date_due,
               @date_due AS date_aging,
               armaster.customer_code AS customer_code,
               ' ' AS ship_to_code,
               armaster.salesperson_code AS salesperson_code,
               armaster.territory_code,
               '' AS comment_code,
               '' AS fob_code,
               '' freight_code,
               armaster.terms_code AS terms_code,
               '' AS fin_chg_code,
               '' AS price_code,
               '' AS dest_zone_code,
               armaster.posting_code AS Posting_Code,
               0 AS recurring_flag,
               '' AS recurring_code,
               armaster.tax_code AS tax_code,
               '' AS Customer_PO,
               0 AS total_weight,
               @disc_cback AS amt_gross,
               0 AS amt_freight,
               0 AS amt_tax,
               0 AS amt_tax_included,
               0 AS amt_discount,
               @disc_cback AS amt_net,
               0 AS amt_paid,
               @disc_cback AS amt_due,
               0 AS amt_cost,
               0 AS amt_profit,
               1 AS next_serial_id,
               1 AS printed_flag,
               0 AS posted_flag,
               0 AS hold_flag,
               ' ' AS hold_desc,
               1 AS user_id,
               armaster.addr1,
               armaster.addr2,
               armaster.addr3,
               armaster.addr4,
               armaster.addr5,
               armaster.addr6,
               ' ',
               ' ',
               ' ',
               ' ',
               ' ',
               ' ',
               ' ',
               ' ',
               0,
               0,
               0,
               ' ',
               ' ',
               ' ',
               NULL,
               0,
               0,
               'USD' AS nat_cur_code,
               'BUY' AS rate_type_home,
               'BUY' AS rate_type_oper,
               1 AS rate_home,
               1 AS rate_oper,
               0,
               NULL,
               NULL,
               NULL,
               'CVO' AS org_id,
               armaster.country_code,
               armaster.city,
               armaster.state,
               armaster.postal_code,
               ' ',
               ' ',
               ' ',
               ' '
        FROM arcust armaster
        WHERE @customer_code = armaster.customer_code;

        IF @@error <> 0
            SELECT @ErrFlag = 10;

        ---------------------------------------------------------    
        /*arinpcdt*/
        ---------------------------------------------------------   

        INSERT INTO arinpcdt
        SELECT NULL AS timestamp,
               @control_number_inv AS trx_ctrl_num,
               @doc_ctrl_number_inv,
               tdet.lne_id AS sequence_id,
               2031 AS trx_type,
               ' ' AS location_code,
               ' ' AS item_code,
               0 AS bulk_flag,
               @cutoff_date AS date_entered,
               doc_ctrl_num + ' / ' + order_ctrl_num AS line_desc,
               1 AS qty_ordered,
               1 AS qty_shipped,
               ' ',
               tdet.disc_given AS unit_price,
               0,
               0,
               0 AS serial_id,
               armaster.tax_code AS tax_code,
               '4920000000000',
               0,
               0 AS amt_discount,
               0,
               '' AS rma_num,
               ' ',
               0 AS qty_returned,
               0 AS qty_prev_returned,
               ' ',
               0,
               0,
               0,
               tdet.disc_given AS extended_price,
               0 AS calc_tax,
               '' AS reference_code,
               '' AS new_reference_code,
               ' ',
               'CVO' AS org_id
        FROM arcust armaster,
             #TempDet tdet
        WHERE @customer_code = armaster.customer_code
              AND @customer_code = tdet.customer_code;

        IF @@error <> 0
            SELECT @ErrFlag = 20;

        --------------------------------------------------------    
        /*arinpage*/
        ---------------------------------------------------------    

        INSERT INTO arinpage
        SELECT NULL,
               @control_number_inv AS trx_ctrl_num,
               1,
               @doc_ctrl_number_inv,
               ' ',
               0,
               2031 AS trx_type,
               @cutoff_date AS date_applied,
               @date_due AS date_due,
               @date_due AS date_aging,
               @customer_code,
               armaster.salesperson_code,
               armaster.territory_code,
               armaster.price_code,
               @disc_cback
        FROM arcust armaster
        WHERE @customer_code = armaster.customer_code;

        IF @@error <> 0
            SELECT @ErrFlag = 30;

        --------------------------------------------------------    
        /*arinptax*/
        ---------------------------------------------------------    

        INSERT INTO arinptax
        SELECT NULL AS timestamp,
               @control_number_inv AS trx_ctrl_num,
               2031 AS trx_type,
               1 AS sequence_id,
               armaster.tax_code AS tax_type_code,
               @disc_cback AS amt_taxable,
               @disc_cback AS amt_gross,
               0 AS amt_tax,
               0 AS amt_final_tax
        FROM arcust armaster
        WHERE @customer_code = armaster.customer_code;

        IF @@error <> 0
            SELECT @ErrFlag = 40;


        IF @ErrFlag = 0
        BEGIN
            COMMIT TRANSACTION;
        END;
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
        END;


        DROP TABLE #TempDet;

        FETCH NEXT FROM ap01
        INTO @id_no,
             @customer_code,
             @disc_cback;

    END; -- loop statement for creating cb invoices

    CLOSE ap01;
    DEALLOCATE ap01;

    DROP TABLE #TempSum;

END; -- if

SELECT id_no,
       customer_code,
       cust_name,
       doc_ctrl_num,
       trx_ctrl_num,
       date_due,
       shipped,
       invoice_unit,
       list_unit,
       disc_given,
       CASE WHEN disc_given <> 0 AND list_unit <> 0 THEN round((list_unit-invoice_unit)/list_unit*100,1) ELSE 0 end disc_pct,
       disc_nochg,
       why,
       order_ctrl_num,
       part_no,
       bg_code,
       trx_type,
       @cutoff_date AS cutoff_date,
       @Create_doc AS create_doc
FROM #Temp
ORDER BY customer_code;
-- , trx_ctrl_num

DROP TABLE #Temp;
DROP TABLE #past_due_bal;
DROP TABLE #Temp_inv;
DROP TABLE #tmp_CustBal;
DROP TABLE #tmp_CustBal_Open;
DROP TABLE #tmp_bgbal;
DROP TABLE #tmp_bgBal_Open;
DROP TABLE #Temp_pp;
DROP TABLE #Temp_cr;
DROP TABLE #Temp_cash;




GO
GRANT EXECUTE ON  [dbo].[cvo_chargebacks_sp] TO [public]
GO
