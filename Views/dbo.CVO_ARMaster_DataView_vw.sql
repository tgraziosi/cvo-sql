SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[CVO_ARMaster_DataView_vw]
AS
-- created by elizabeth labarbera
SELECT     
CASE status_type WHEN '1' THEN 'Active' 
    WHEN '2' THEN 'NoNewBus' 
    ELSE 'INActive' END AS STATUS, 
    ar.customer_code, 
	ar.ship_to_code,
    ar.address_name, 
    ISNULL(ar.city, '') AS City, 
    ISNULL(ar.state, '') AS State, 
    ar.addr2, 
    ar.addr3, 
    ar.addr4, 
    ar.country_code, 
    ISNULL(ar.contact_phone, '') AS Phone, 
    ISNULL(ar.tlx_twx, '') AS Fax,
    ar.territory_code, 
    ar.salesperson_code, 
    ar.addr_sort1 AS Type, 
    ar.terms_code, 
    ar.fin_chg_code, 
    ar.price_code, 
    ar.payment_code, 
    ar.print_stmt_flag, 
    ar.stmt_cycle_code, 
    ar.credit_limit, 
    check_credit_limit, 
    check_aging_limit, 
    CASE WHEN aging_limit_bracket IS NULL OR aging_limit_bracket  = 0 THEN ''
         WHEN aging_limit_bracket = 1 THEN 30	
         WHEN aging_limit_bracket = 2 THEN 60  
         WHEN aging_limit_bracket = 3 THEN 90	
         WHEN aging_limit_bracket = 4 THEN 120
         ELSE '' END AS aging_limit_bracket, 
    limit_by_home,
    ar.tax_code, 
    ISNULL(ar.resale_num, '') AS ReSaleCert, 
    dbo.cvo_fn_rem_crlf(ISNULL(ar.url,'')) url,
    ar.so_priority_code, 
    ISNULL(ar.ftp, '') AS BG_Acct_#, 
    ISNULL(na.parent, '') AS 'PARENT/BG', ISNULL(contact_name,'') Contact_name, 
    ISNULL(contact_email,'') Contact_email, 
    STATUS_TYPE,
	ar.added_by_date,
	CASE WHEN ar.added_by_user_name BETWEEN '1' AND '900' THEN uu.USER_NAME ELSE  ISNULL(ar.added_by_user_name,'') END AS added_by_user_name,
	ar.modified_by_date,
	CASE WHEN ar.modified_by_user_name BETWEEN '1' AND '900' THEN u.USER_NAME ELSE  ISNULL(ar.modified_by_user_name,'') END AS modified_by_user_name
FROM dbo.armaster AS ar WITH (NOLOCK) 
	LEFT OUTER JOIN dbo.CVO_armaster_all AS car WITH (NOLOCK) ON ar.customer_code = car.customer_code AND ar.ship_to_code = car.ship_to 
     LEFT OUTER JOIN dbo.arnarel AS na WITH (NOLOCK) ON car.customer_code = na.child
	 LEFT OUTER JOIN CVO_CONTROL..SMUSERS u ON RTRIM(ar.modified_by_user_name)=CAST(u.USER_ID AS VARCHAR(30))
	 LEFT OUTER JOIN CVO_CONTROL..SMUSERS uu ON RTRIM(ar.added_by_user_name)=CAST(uu.USER_ID AS VARCHAR(30))
--WHERE     (t1.address_type = '0')   --7/2/14 EL updated to add ship_to's



GO
GRANT CONTROL ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
GRANT REFERENCES ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_ARMaster_DataView_vw] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "t1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 256
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t2"
            Begin Extent = 
               Top = 6
               Left = 294
               Bottom = 125
               Right = 499
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "t3"
            Begin Extent = 
               Top = 6
               Left = 537
               Bottom = 125
               Right = 743
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'CVO_ARMaster_DataView_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CVO_ARMaster_DataView_vw', NULL, NULL
GO
