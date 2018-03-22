SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[cvo_whse_missing_assignments_vw]
AS
SELECT i.category Collection,
       ia.field_2 Style,
       i.part_no,
       i.description,
       i.type_code,
       pa.attribute,
       ia.field_26 rel_date,
       ia.field_28 pom_date,
       POM_age = CASE WHEN DATEDIFF(DAY, ISNULL(ia.field_28, GETDATE()), GETDATE()) <= 0 THEN 'CURRENT'
                 WHEN DATEDIFF(YEAR, ISNULL(ia.field_28, GETDATE()), GETDATE()) < 2 THEN 'Y1 POM' ELSE 'Y2+ POM'
                 END,
       CASE WHEN PICK.bin_no IS NULL AND i.type_code IN ( 'frame', 'sun', 'pattern' ) THEN 'Missing' ELSE PICK.bin_no END Pick_Bin,
       CASE WHEN HB.bin_no IS NULL AND i.type_code IN ( 'frame' ) THEN 'Missing' ELSE HB.bin_no END Highbay_Bin,
       CASE WHEN RESERVE.bin_no IS NULL AND i.type_code IN ( 'frame', 'sun' ) THEN 'Missing' ELSE RESERVE.bin_no END Reserve_Bin,
       il.location
FROM dbo.inv_master i (NOLOCK)
    JOIN dbo.inv_master_add ia (NOLOCK)
        ON ia.part_no = i.part_no
    JOIN dbo.inv_list il (NOLOCK)
        ON il.part_no = i.part_no
    LEFT OUTER JOIN
    (
    SELECT c.part_no,
           STUFF(
           (
           SELECT '; ' + attribute
           FROM dbo.cvo_part_attributes pa2 (NOLOCK)
           WHERE pa2.part_no = c.part_no
           FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) attribute
    FROM dbo.cvo_part_attributes c
    ) AS pa
        ON pa.part_no = i.part_no
    LEFT OUTER JOIN
    (
    SELECT bp.part_no,
           bp.location,
           bp.bin_no
    FROM dbo.tdc_bin_part_qty bp
        JOIN dbo.tdc_bin_master b
            ON b.bin_no = bp.bin_no
               AND b.location = bp.location
    WHERE b.group_code = 'PICKAREA'
    ) PICK
        ON PICK.part_no = i.part_no
           AND PICK.location = il.location
    LEFT OUTER JOIN
    (
    SELECT bp.part_no,
           bp.location,
           bp.bin_no
    FROM dbo.tdc_bin_part_qty bp
        JOIN dbo.tdc_bin_master b
            ON b.bin_no = bp.bin_no
               AND b.location = bp.location
    WHERE b.group_code = 'HIGHBAY'
    ) HB
        ON HB.part_no = i.part_no
           AND HB.location = il.location
    LEFT OUTER JOIN
    (
    SELECT bp.part_no,
           bp.location,
           bp.bin_no
    FROM dbo.tdc_bin_part_qty bp
        JOIN dbo.tdc_bin_master b
            ON b.bin_no = bp.bin_no
               AND b.location = bp.location
    WHERE b.group_code = 'RESERVE'
    ) RESERVE
        ON RESERVE.part_no = i.part_no
           AND RESERVE.location = il.location
WHERE i.void = 'n'
      AND i.type_code IN ( 'frame', 'sun', 'pattern' )
      AND ISNULL(ia.field_28, '12/31/2020') > GETDATE()
      AND
      (
      (PICK.bin_no IS NULL)
      OR
      (
      HB.bin_no IS NULL
      AND i.type_code = 'frame'
      )
      OR
      (
      RESERVE.bin_no IS NULL
      AND i.type_code IN ( 'frame', 'sun' )
      )
      );




GO
GRANT SELECT ON  [dbo].[cvo_whse_missing_assignments_vw] TO [public]
GO
