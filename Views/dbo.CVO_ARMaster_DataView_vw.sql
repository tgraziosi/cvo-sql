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
    t1.customer_code, 
	t1.ship_to_code,
    t1.address_name, 
    ISNULL(t1.city, '') AS City, 
    ISNULL(t1.state, '') AS State, 
    t1.addr2, 
    t1.addr3, 
    t1.addr4, 
    t1.country_code, 
    ISNULL(t1.contact_phone, '') AS Phone, 
    ISNULL(t1.tlx_twx, '') AS Fax,
    t1.territory_code, 
    t1.salesperson_code, 
    t1.addr_sort1 as Type, 
    t1.terms_code, 
    t1.fin_chg_code, 
    t1.price_code, 
    t1.payment_code, 
    t1.print_stmt_flag, 
    t1.stmt_cycle_code, 
    t1.credit_limit, 
    check_credit_limit, 
    check_aging_limit, 
    case when aging_limit_bracket is null OR aging_limit_bracket  = 0 then ''
         when aging_limit_bracket = 1 then 30	
         when aging_limit_bracket = 2 then 60  
         when aging_limit_bracket = 3 then 90	
         when aging_limit_bracket = 4 then 120
         else '' end as aging_limit_bracket, 
    limit_by_home,
    t1.tax_code, 
    ISNULL(t1.resale_num, '') AS ReSaleCert, 
    t1.url,
    t1.so_priority_code, 
    ISNULL(t1.ftp, '') AS BG_Acct_#, 
    ISNULL(t3.parent, '') AS 'PARENT/BG', isnull(contact_name,'') Contact_name, 
    isnull(contact_email,'') Contact_email, 
    STATUS_TYPE,
	t1.added_by_date,
	CASE WHEN t1.added_by_user_name BETWEEN '1' AND '900' THEN t5.USER_NAME ELSE  ISNULL(t1.added_by_user_name,'') END AS added_by_user_name,
	t1.modified_by_date,
	CASE WHEN t1.modified_by_user_name BETWEEN '1' AND '900' THEN t4.USER_NAME ELSE  ISNULL(t1.modified_by_user_name,'') END AS modified_by_user_name
FROM dbo.armaster AS t1 WITH (nolock) 
	LEFT OUTER JOIN dbo.CVO_armaster_all AS t2 WITH (nolock) ON t1.customer_code = t2.customer_code AND t1.ship_to_code = t2.ship_to 
     LEFT OUTER JOIN dbo.arnarel AS t3 WITH (nolock) ON t2.customer_code = t3.child
	 LEFT OUTER JOIN CVO_CONTROL..SMUSERS T4 ON rtrim(T1.modified_by_user_name)=cast(T4.USER_ID as varchar(30))
	 LEFT OUTER JOIN CVO_CONTROL..SMUSERS T5 ON rtrim(T1.added_by_user_name)=cast(T5.USER_ID as varchar(30))
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
