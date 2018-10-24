SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_desig_bg_mismatch_sp]
AS
BEGIN

    -- have designation, does not match BG

    SELECT s.customer_code child,
           s.customer_code,
           s.code,
           s.description,
           s.start_date,
           s.end_date,
           s.primary_flag,
           s.Current_BG,
           s.err_msg
    FROM
    (
        SELECT d.customer_code,
               d.code,
               d.description,
               d.start_date,
               d.end_date,
               CASE
                   WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                       'Yes'
                   ELSE
                       'No'
               END AS primary_flag,
               dbo.f_cvo_get_buying_group(customer_code, GETDATE()) Current_BG,
               'Designation does not Match BG' err_msg
        FROM cvo_cust_designation_codes d
        WHERE code IN ( 'bbg', 'fec-a', 'fec-m', 'oogp', 'villa', 'vwest', 'CE' )
              AND ISNULL(end_date, GETDATE()) >= GETDATE()
    ) s
    WHERE (
              code = 'bbg'
              AND ISNULL(Current_BG, '') <> '000502'
          )
          OR
          (
              code = 'ce'
              AND ISNULL(Current_BG, '') <> '000507'
          )
          OR
          (
              code IN ( 'fec-a', 'fec-m' )
              AND ISNULL(Current_BG, '') <> '000550'
          )
          OR
          (
              code IN ( 'oogp' )
              AND ISNULL(Current_BG, '') <> '000542'
          )
          OR
          (
              code IN ( 'villa' )
              AND ISNULL(Current_BG, '') <> '000549'
          )
          OR
          (
              code IN ( 'vwest' )
              AND ISNULL(Current_BG, '') <> '000563'
          )
    UNION ALL
    -- have BG, does not match designation

    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000502',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000502', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code = 'bbg'
    WHERE c.child <> ISNULL(d.customer_code, '')
    UNION ALL
    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000507',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000507', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code = 'CE'
    WHERE c.child <> ISNULL(d.customer_code, '')
    UNION ALL
    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000550',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000550', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code IN ( 'fec-a', 'fec-m' )
    WHERE c.child <> ISNULL(d.customer_code, '')
    UNION ALL
    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000542',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000542', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code IN ( 'oogp' )
    WHERE c.child <> ISNULL(d.customer_code, '')
    UNION ALL
    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000549',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000549', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code IN ( 'villa' )
    WHERE c.child <> ISNULL(d.customer_code, '')
    UNION ALL
    SELECT c.child,
           d.customer_code,
           d.code,
           d.description,
           d.start_date,
           d.end_date,
           CASE
               WHEN ISNULL(d.primary_flag, 0) = 1 THEN
                   'Yes'
               ELSE
                   'No'
           END AS primary_flag,
           '000563',
           'BG does not match Designation' err_msg
    FROM dbo.f_cvo_get_buying_group_child_list('000563', GETDATE()) c
        LEFT OUTER JOIN dbo.cvo_cust_designation_codes d
            ON c.child = d.customer_code
               AND d.code IN ( 'vwest' )
    WHERE c.child <> ISNULL(d.customer_code, '');

END;
GO
GRANT EXECUTE ON  [dbo].[cvo_desig_bg_mismatch_sp] TO [public]
GO
