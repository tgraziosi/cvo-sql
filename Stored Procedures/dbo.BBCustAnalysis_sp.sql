SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 4/5/2013
-- Description:	Business Builder Customer Analysis
--  EXEC BBCustAnalysis_sp 2016
-- tag - 6/4/2015 - change sales table to cvo_sbm_details
-- tag - 101717 - add RA Pct and rewrite in general
-- =============================================
CREATE PROCEDURE [dbo].[BBCustAnalysis_sp]
    @Year INT
AS
    BEGIN
        -- SET NOCOUNT ON added to prevent extra result sets from
        -- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF ( OBJECT_ID('tempdb.dbo.#BB1') IS NOT NULL )
            DROP TABLE #BB1;
        SELECT   BB.progyear AS Year ,
                 MAR.territory_code MTERR ,
                 BB.master_cust_code ,
                 MAR.address_name MNAME ,
                 AR.territory_code AS Terr ,
                 BB.cust_code ,
                 AR.address_name AS NAME ,
                 AR.city ,
                 AR.state ,
                 SUM(goal1) Goal1 ,
                 SUM(rebatepct1) RebatePct1 ,
                 SUM(goal2) Goal2 ,
                 SUM(rebatepct2) RebatePct2 ,
                 SUM(lys.LYS) lys ,
                 SUM(tys.tys) tys ,
				 SUM(TYS.TYgrosssales) TYgrosssales,
				 SUM(lys.LYgrosssales) LYgrosssales,
				 SUM(tys.TYrareturns)  TYrareturns,
				 SUM(lys.LYrareturns)  LYrareturns,
                 (   SELECT goal1
                     FROM   cvo_businessbuildercusts BB2
                     WHERE  BB2.master_cust_code = BB.master_cust_code
                            AND BB2.cust_code = BB.cust_code
                            AND BB2.progyear = ( @Year - 1 )
                            AND BB2.goal1 IS NOT NULL ) LYGoal1 ,
                 (   SELECT goal2
                     FROM   cvo_businessbuildercusts BB2
                     WHERE  BB2.master_cust_code = BB.master_cust_code
                            AND BB2.cust_code = BB.cust_code
                            AND BB2.progyear = ( @Year - 1 )
                            AND BB2.goal2 IS NOT NULL ) LYGoal2
        INTO     #BB1
        FROM     cvo_businessbuildercusts BB ( NOLOCK )
                 JOIN armaster AR ( NOLOCK ) ON BB.cust_code = AR.customer_code
                 JOIN armaster MAR ( NOLOCK ) ON BB.master_cust_code = MAR.customer_code
                 LEFT OUTER JOIN (   SELECT   RIGHT(customer, 5) customer ,
                                              SUM(ISNULL(anet,0)) LYS,
											  SUM(ISNULL(asales,0)) - SUM(ISNULL((CASE WHEN return_code='exc' THEN areturns ELSE 0 end),0)) LYgrosssales, 
											  SUM(CASE WHEN ISNULL(return_code,'') = '' THEN ISNULL(areturns,0) ELSE 0 END) LYrareturns

                                     FROM     cvo_sbm_details
                                     WHERE    yyyymmdd
                                     BETWEEN  ( '1/1/'
                                                + CONVERT(VARCHAR, ( @Year - 1 ))) AND ( '12/31/'
                                                                                         + CONVERT(
                                                                                               VARCHAR ,
                                                                                               ( @Year
                                                                                                 - 1 ))
                                                                                         + ' 23:59:59' )
                                     GROUP BY RIGHT(customer, 5)) lys ON lys.customer = RIGHT(BB.cust_code, 5)
                 LEFT OUTER JOIN (   SELECT   RIGHT(customer, 5) customer ,
                                              SUM(anet) tys,
											  SUM(ISNULL(asales,0)) - SUM(ISNULL((CASE WHEN return_code='exc' THEN areturns ELSE 0 end),0)) TYgrosssales, 
											  SUM(CASE WHEN ISNULL(return_code,'') = '' THEN ISNULL(areturns,0) ELSE 0 END) TYrareturns
                                     FROM     cvo_sbm_details
                                     WHERE    yyyymmdd
                                     BETWEEN  ( '1/1/'
                                                + CONVERT(VARCHAR, ( @Year ))) AND ( '12/31/'
                                                                                     + CONVERT(
                                                                                           VARCHAR ,
                                                                                           ( @Year ))
                                                                                     + ' 23:59:59' )
                                     GROUP BY RIGHT(customer, 5)) tys ON tys.customer = RIGHT(BB.cust_code, 5)
        WHERE    BB.progyear = @Year
                 AND AR.address_type = 0
                 AND MAR.address_type = 0

        GROUP BY BB.progyear ,
                 MAR.territory_code ,
                 BB.master_cust_code ,
                 MAR.address_name ,
                 AR.territory_code ,
                 BB.cust_code ,
                 AR.address_name ,
                 AR.city ,
                 AR.state

        ORDER BY BB.master_cust_code ,
                 BB.cust_code;

        SELECT   Year ,
                 MTERR ,
                 T1.master_cust_code ,
                 MNAME ,
                 Terr ,
                 cust_code ,
                 NAME ,
                 city ,
                 state ,
                 Goal1 ,
                 ( Goal1 - t11.lys ) / t11.lys LYVG1 ,
                 RebatePct1 ,
                 Goal2 ,
                 (( Goal2 - t11.lys ) / ( t11.lys )) LYVG2 ,
                 RebatePct2 ,
                 T1.tys ,
                 CASE WHEN Goal1 IS NULL THEN NULL
                      ELSE t11.tys
                 END AS TYSM ,
                 CASE WHEN Goal1 IS NULL THEN NULL
                      ELSE ( t11.tys / Goal1 )
                 END AS G1PctAch ,
                 CASE WHEN Goal1 IS NULL THEN NULL
                      WHEN ( t11.tys - Goal1 ) > 1 THEN 0
                      ELSE ( t11.tys - Goal1 ) * -1
                 END AS G1Diff ,
                 CASE WHEN Goal2 IS NULL THEN NULL
                      ELSE ( t11.tys / Goal2 )
                 END AS G2PctAch ,
                 CASE WHEN Goal2 IS NULL THEN NULL
                      ELSE ( t11.tys - Goal2 )
                 END AS G2Diff ,
                 T1.lys ,
                 CASE WHEN LYGoal1 IS NULL THEN NULL
                      ELSE t11.lys
                 END AS LYSM ,
                 LYGoal1 ,
                 CASE WHEN LYGoal1 IS NULL THEN NULL
                      ELSE ( t11.lys / LYGoal1 )
                 END AS LYG1PctAch ,
                 LYGoal2 ,
                 CASE WHEN LYGoal2 IS NULL THEN NULL
                      ELSE ( t11.lys / LYGoal2 )
                 END AS LYG2PctAch ,
				 LYraretpct = CASE WHEN LYgrosssales = 0 THEN 0 ELSE LYrareturns/LYgrosssales END,
				 TYraretpct = CASE WHEN TYgrosssales = 0 THEN 0 ELSE TYrareturns/TYgrosssales END,
                 CASE WHEN T1.master_cust_code = T1.cust_code THEN 'x'
                      ELSE ''
                 END AS Line ,
                 t11.count_master CntM

        FROM     #BB1 T1
                 JOIN (   SELECT   master_cust_code ,
                                   SUM(lys) lys ,
                                   SUM(tys) tys ,
                                   COUNT(master_cust_code) count_master
                          FROM     #BB1
                          GROUP BY master_cust_code ) t11 ON t11.master_cust_code = T1.master_cust_code

        ORDER BY T1.master_cust_code ,
                 T1.cust_code;


    END;


GO
GRANT EXECUTE ON  [dbo].[BBCustAnalysis_sp] TO [public]
GO
