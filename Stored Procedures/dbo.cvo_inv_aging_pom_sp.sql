SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_inv_aging_pom_sp]
(
    @asofdate DATETIME,
    @loc VARCHAR(12),
    @type VARCHAR(1000)
)
AS
BEGIN
-- exec cvo_inv_aging_pom_sp '12/11/2017', '001', 'frame,sun'
SET NOCOUNT ON;

-- declare @asofdate datetime, @loc varchar(12), @type varchar(1000)

IF (OBJECT_ID('tempdb.dbo.#type') IS NOT NULL)
    DROP TABLE #type;

CREATE TABLE #type
(
    restype VARCHAR(10)
);

INSERT INTO #type
(
    restype
)
SELECT ListItem
FROM dbo.f_comma_list_to_table(@type);

CREATE TABLE #filters
(
    brand VARCHAR(10) NULL,
	gender VARCHAR(10) NULL,
	restype VARCHAR(10) NULL

);

/*
select @asofdate = getdate()
select @loc = '001'
select @type = 'frame'
*/

SELECT cia.Brand,
       cia.ResType,
       cia.Style,
       g.description Gender,
       CASE
           WHEN et.part_no IS NOT NULL THEN
               'EOS'
           ELSE
               ''
       END AS eos,
       cia.part_no,
       cia.description,
       cia.POM_date,
       age = CASE
                 WHEN cia.POM_date > @asofdate THEN
                     'Future'
                 WHEN cia.POM_date >= DATEADD(yy, -1, @asofdate) THEN
                     '<1'
                 WHEN cia.POM_date >= DATEADD(yy, -2, @asofdate)
                      AND cia.POM_date < DATEADD(yy, -1, @asofdate) THEN
                     '<2'
                 WHEN cia.POM_date >= DATEADD(yy, -3, @asofdate)
                      AND cia.POM_date < DATEADD(yy, -2, @asofdate) THEN
                     '<3'
                 WHEN cia.POM_date < DATEADD(yy, -3, @asofdate) THEN
                     '>3'
                 ELSE
                     'Unknown'
             END,
       cia.tot_cost_ea,
       cia.tot_ext_cost,
       cia.in_stock,
       cia.qty_avl,
       cia.SOF,
       cia.Allocated,
       cia.Quarantine,
       cia.Non_alloc,
       cia.Replen_Qty_Not_SA,
       cia.ReplenQty,
	   cia.Material,
	   cia.Color_desc
FROM cvo_item_avail_vw cia (NOLOCK)
    INNER JOIN #type
        ON #type.restype = cia.ResType
    LEFT OUTER JOIN 
    (SELECT DISTINCT part_no FROM dbo.cvo_part_attributes AS pa WHERE pa.attribute = 'eos') et
        ON et.part_no = cia.part_no -- AND et.obs_date IS NULL
    JOIN cvo_gender g ON g.kys = cia.gender

WHERE cia.POM_date IS NOT NULL
      AND cia.POM_date <= @asofdate
      AND location = @loc
      AND
      (
          cia.in_stock <> 0
          OR cia.tot_ext_cost <> 0
      );
END


GO
GRANT EXECUTE ON  [dbo].[cvo_inv_aging_pom_sp] TO [public]
GO
