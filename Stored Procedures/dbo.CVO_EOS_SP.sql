SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		ELABARBERA
-- Create date: 5/17/2013
-- Description:	LISTS FOR EOS - END OF SUNS
-- EXEC CVO_EOS_SP
-- 090314 - tag - read sku list from new table cvo_eos_tbl
-- 11092018 - switch to look for an attribute instead of cvo_eos_tbl
-- =============================================

CREATE PROCEDURE [dbo].[CVO_EOS_SP]
AS
    BEGIN

        SET NOCOUNT ON;

        DECLARE @numberOfColumns INT;
        SET @numberOfColumns = 3;

        IF (OBJECT_ID('tempdb.dbo.#Data') IS NOT NULL)
            DROP TABLE #Data;

        SELECT
            s.Prog,
            s.brand,
            s.style,
            s.part_no,
            s.POM_Date,
            s.Gender,
            s.Avail,
            s.ReserveQty,
            s.TrueAvail
        INTO
            #Data
        FROM
            (
                SELECT
                        'EOS'     AS Prog,
                        brand,
                        style,
                        eos.part_no,
                        POM_Date,
                        CASE
                            WHEN Gender LIKE '%CHILD%'
                                THEN
                                'Kids'
                            WHEN Gender = 'FEMALE-ADULT'
                                THEN
                                'Womens'
                            ELSE
                                'Mens'
                        END       AS Gender,
                        Avail,
                        ReserveQty,
                        Avail     AS TrueAvail
                -- tag 090314 - change to table from list of skus
                FROM
                        -- cvo_eos_tbl              eos (NOLOCK)
                        cvo_part_attributes eos (nolock)
                    LEFT OUTER JOIN
                        CVO_items_discontinue_vw id (NOLOCK)
                            ON eos.part_no = id.part_no
                WHERE
                        ISNULL(id.type, 'SUN') = 'SUN'
                        -- AND eos.eff_date < GETDATE()
                        -- AND ISNULL(eos.obs_date, GETDATE()) >= GETDATE()
                        AND eos.attribute = 'eos'
            ) s
        ORDER BY
            Prog,
            Gender,
            brand,
            style,
            part_no;


        -- select * from #Data where TrueAvail=0


        IF (OBJECT_ID('tempdb.dbo.#Num') IS NOT NULL)
            DROP TABLE #Num;
        SELECT DISTINCT
               Prog,
               Gender,
               brand,
               style,
               ROW_NUMBER() OVER (ORDER BY
                                      Prog,
                                      Gender,
                                      brand,
                                      style
                                 ) AS Num
        INTO
               #Num
        FROM
               #Data
        GROUP BY
               Prog,
               Gender,
               brand,
               style
        ORDER BY
               Prog,
               Gender,
               brand,
               style;

        -- select * from #data
        -- select * from #Num

        --select CASE WHEN Num%2=0 THEN 0 ELSE 1 END as Col, * from #Data t1 join #num t2 on t1.prog=t2.prog and t1.brand=t2.brand and t1.style=t2.style
        SELECT  ((Num + @numberOfColumns - 1) % @numberOfColumns + 1) AS Col,
                t1.Prog,
                t1.brand,
                t1.style,
                t1.part_no,
                t1.POM_Date,
                t1.Gender,
                t1.Avail,
                t1.ReserveQty,
                t1.TrueAvail                                          AS TrueAvail_2,
                CASE
                    WHEN t1.TrueAvail > 100
                        THEN
                        '100+'
                    ELSE
                        CONVERT(VARCHAR(20), CONVERT(INT, t1.TrueAvail))
                END                                                   AS TrueAvail
        FROM
                #Data t1
            JOIN
                #Num  t2
                    ON t1.Prog = t2.Prog
                       AND t1.Gender = t2.Gender
                       AND t1.brand = t2.brand
                       AND t1.style = t2.style
        ORDER BY
                Prog,
                Gender,
                brand,
                style;

    END;




GO
