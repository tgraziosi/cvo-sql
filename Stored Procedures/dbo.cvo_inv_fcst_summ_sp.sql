SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_inv_fcst_summ_sp] 

-- 12/27/2016
-- Summary Values
-- re-write for y1 figures not pulling enough history to properly generate

/*

EXEC CVo_inv_fcst_summ_sp 
				@asofdate = '04/01/2017', 
				@endrel = '04/01/2017',
                @collection = 'cvo',
				@Style = '*all*',
                @SpecFit = '*all*',
                @location = '001';

*/

    @asofdate DATETIME ,
    @location VARCHAR(10) ,
    @endrel DATETIME = NULL , -- ending release date
    @current INT = 1 ,
    @collection VARCHAR(1000) = NULL ,
    @Style VARCHAR(8000) = NULL ,
    @SpecFit VARCHAR(1000) = NULL ,
    @gender VARCHAR(1000) = NULL ,
	@restype VARCHAR(1000) = NULL,
    @usg_option CHAR(1) = 'O' ,
    @Season_start INT = NULL ,
    @Season_end INT = NULL ,
    @Season_mult DECIMAL(20, 8) = NULL ,
    @spread VARCHAR(10) = NULL ,
    @debug INT = 0
--
AS

	SET NOCOUNT ON;

-- SELECT * FROM #s AS s

    CREATE TABLE #ifp
        (
    brand VARCHAR(10),
    style VARCHAR(40),
    vendor VARCHAR(12),
    type_code VARCHAR(10),
    gender VARCHAR(15),
    material VARCHAR(40),
    moq VARCHAR(255),
    watch VARCHAR(15),
    sf VARCHAR(40),
    rel_date DATETIME,
    pom_date DATETIME,
    mth_since_rel INT,
    s_sales_m1_3 FLOAT(8),
    s_sales_m1_12 FLOAT(8),
    s_e4_wu INT,
    s_e12_wu INT,
    s_e52_wu INT,
    s_promo_w4 INT,
    s_promo_w12 INT,
    s_gross_w4 INT,
    s_gross_w12 INT,
    line_type VARCHAR(3),
    sku VARCHAR(30),
    location VARCHAR(12),
    mm INT,
    p_rel_date DATETIME,
    p_pom_date DATETIME,
    lead_time INT,
    bucket DATETIME,
    qoh INT,
    atp INT,
    reserve_qty INT,
    quantity INT,
    mult DECIMAL(20, 8),
    s_mult DECIMAL(20, 8),
    sort_seq INT,
    pct_of_style DECIMAL(37, 19),
    pct_First_po FLOAT(8),
    pct_sales_style_m1_3 FLOAT(8),
    p_e4_wu INT,
    p_e12_wu INT,
    p_e52_wu INT,
    p_subs_w4 INT,
    p_subs_w12 INT,
    s_mth_usg INT,
    p_mth_usg INT,
    s_mth_usg_mult DECIMAL(31, 8),
    p_po_qty_y1 DECIMAL(38, 8),
    ORDER_THRU_DATE DATETIME,
    TIER VARCHAR(1),
    p_type_code VARCHAR(10),
    s_rx_w4 INT,
    s_rx_w12 INT,
    p_rx_w4 INT,
    p_rx_w12 INT,
    s_Ret_w4 INT,
    s_ret_w12 INT,
    p_ret_w4 INT,
    p_ret_w12 INT,
    s_wty_w4 INT,
    s_wty_w12 INT,
    p_wty_w4 INT,
    p_wty_w12 INT,
    p_gross_w4 INT,
    p_gross_w12 INT,
    price DECIMAL(20, 8),
    frame_type VARCHAR(40)
        );

    INSERT  INTO #ifp
            EXEC cvo_inv_fcst_r3_sp
			    @asofdate = @asofdate, 
				@endrel = @endrel, 
				@collection = @collection, 
				@Style = @Style,
                @SpecFit = @SpecFit,
	            @location = @location,
				@restype = 'frame,sun';



   -- DELETE  FROM #ifp
   -- WHERE   sort_seq <> 1
   --         OR line_type <> 'v'
			--OR type_code IN ('parts','bruit');
 
    SELECT  t.brand ,
            t.style ,
			t.sku ,
            t.vendor ,
            t.lead_time ,
            t.type_code ,
			t.p_type_code ,
			UPPER(CASE when GENDER like 'Female-%' then replace(gender,'Female','F')
		when gender like 'Male-%' then replace(gender,'Male','M')
		when gender like 'Unisex-%' then replace(gender,'Unisex','U')
		else isnull(gender,'') END) as Gender,
            -- t.gender ,
            t.material ,
			t.frame_type,
            t.moq ,
            --t.watch ,
            t.sf ,
            t.rel_date ,
            t.pom_date ,
			t.p_rel_date ,
            t.p_pom_date ,
            t.mth_since_rel ,
            t.s_sales_m1_3 ,
            t.s_sales_m1_12 ,
            t.s_e4_wu ,
            t.s_e12_wu ,
            t.s_e52_wu ,
            t.s_promo_w4 ,
            t.s_promo_w12 ,
            --t.line_type ,
            --t.mm ,
			--t.bucket ,
            t.qoh ,
            t.atp ,
            t.reserve_qty ,
            --t.quantity ,
            --t.mult ,
            --t.s_mult ,
            --t.sort_seq ,
            t.pct_of_style ,
            t.pct_First_po ,
            t.pct_sales_style_m1_3 ,
            t.p_e4_wu ,
            t.p_e12_wu ,
            t.p_e52_wu ,
            t.p_subs_w4 ,
            t.p_subs_w12 ,
            t.s_mth_usg ,
            t.p_mth_usg ,
            t.s_mth_usg_mult ,
            --t.sales_y2tg_per_month ,
            --t.sales_y1tg_per_month ,
            t.p_po_qty_y1 ,
            t.ORDER_THRU_DATE ,
            t.TIER ,
			t.s_rx_w4 ,
            t.s_rx_w12 ,
            t.p_rx_w4 ,
            t.p_rx_w12 ,
			t.s_ret_w4 ,
            t.s_ret_w12 ,
			t.p_ret_w4 ,
            t.p_ret_w12 ,
			t.s_wty_w4 ,
            t.s_wty_w12 ,
            t.p_wty_w4 ,
            t.p_wty_w12 ,
			CAST(t.price AS DECIMAL(20,2)) price,
			CAST(ISNULL(il.std_cost + il.std_ovhd_dolrs + il.std_util_dolrs,0) AS DECIMAL(20,8)) std_cost,
			CAST(ISNULL(sbm.s_w12_net_sales,0) AS DECIMAL(20,2)) s_w12_net_sales,
			CAST(ISNULL(sbm.s_w12_net_qty,0) AS DECIMAL(20,2)) s_w12_net_qty,
			CAST(ISNULL(po.s_po_on_order,0) AS int) s_po_on_order,
			'001' AS location

    FROM    #ifp AS t
			LEFT OUTER JOIN inv_list il ON il.part_no = t.sku AND il.location = '001'
			LEFT OUTER JOIN
			(SELECT part_no, SUM(anet) s_w12_net_sales, SUM(qnet) s_w12_net_qty
			FROM dbo.cvo_sbm_details AS sd
			WHERE iscl = 0 AND sd.return_code = ''
			AND yyyymmdd >= DATEADD(WEEK, -12, @asofdate)
			GROUP BY sd.part_no
			) sbm ON sbm.part_no = t.sku 
			LEFT OUTER JOIN
			( SELECT sku, SUM(quantity) s_po_on_order
			FROM #ifp 
			WHERE line_type = 'PO'
			GROUP BY sku) po ON po.sku = t.sku

			WHERE (t.sort_seq = 1 AND t.line_type = 'V'
			AND type_code IN ('frame','sun') AND t.p_type_code <> 'parts'
			AND (t.pom_date IS NULL OR YEAR(t.pom_date) >= YEAR(@asofdate))
			)

			;




GO
GRANT EXECUTE ON  [dbo].[cvo_inv_fcst_summ_sp] TO [public]
GO
