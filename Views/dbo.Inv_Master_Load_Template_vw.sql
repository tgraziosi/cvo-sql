SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[Inv_Master_Load_Template_vw]
AS
SELECT TOP (100) PERCENT 
t1.part_no, 
t1.upc_code, 
t1.sku_no, 
t1.description, 
t1.vendor,
t1.category, 
t1.type_code, 
t1.status, 
t1.cubic_feet, 
t1.weight_ea, 
t1.labor, 
t1.uom, 
t1.account, 
t1.comm_type, 
t1.void, 
t1.void_who, 
t1.void_date, 
t1.entered_who, 
t1.entered_date, 
t1.std_cost, 
t1.utility_cost, 
t1.qc_flag, 
t1.lb_tracking, 
t1.rpt_uom, 
t1.freight_unit, 
t1.taxable, 
t1.freight_class, 
t1.conv_factor, 
t1.note, t1.cycle_type,
t1.inv_cost_method, 
t1.buyer, 
t1.cfg_flag, 
t1.allow_fractions, 
t1.tax_code, 
t1.obsolete, 
t1.serial_flag, 
t1.web_saleable_flag, 
t1.reg_prod, 
t1.warranty_length, 
t1.call_limit, 
t1.yield_pct, 
t1.tolerance_cd, 
t1.pur_prod_flag, 
t1.sales_order_hold_flag, 
t1.abc_code, 
t1.abc_code_frozen_flag, 
t1.country_code, 
t1.cmdty_code, t1.height, 
t1.width, t1.length, 
t1.min_profit_perc, 
t1.sku_code, 
t1.eprocurement_flag, t1.non_sellable_flag, 
t1.so_qty_increment, 
t2.category_1 AS [Watch ?], 
t2.category_2 AS Gender, 
t2.category_3 AS [Part Type], 
t2.category_4 AS Age, 
t2.category_5 AS [Color Code], 
t2.datetime_1 AS [Discontinued On], 
t2.datetime_2 AS [Backorder Date], 
t2.field_1 AS [Case Part], 
t2.field_2 AS [Style/Model Name], 
t2.field_3 AS [Color Description], 
t2.field_4 AS Pattern, 
t2.field_5 AS Polarized, 
t2.field_6 AS [Bridge Size], 
t2.field_7 AS [Nose Pad Type], 
t2.field_8 AS [Temple Size], 
t2.field_9 AS [Total Temple Length], 
t2.field_10 AS [Frame Material], 
t2.field_11 AS [Frame Type], 
t2.field_12 AS [Temple Material], 
t2.field_13 AS [Temple/Hinge Type], 
t2.field_14, 
t2.field_15, 
t2.field_16, 
t2.long_descr AS [Item Notes], 
t2.field_17 AS [Eye Size], 
t2.field_18 AS [Extra Temple], 
t2.field_19 AS [A Measure], 
t2.field_20 AS [B Measure], 
t2.field_21 AS [ED Measure], 
t2.field_22 AS Clip, 
t2.field_23 AS [Sun lens color], 
t2.field_24 AS [Sun lens material], 
t2.field_25 AS [Sun lens type], 
t2.field_26 AS [Rel. date], 
t2.field_27 AS Royalties, 
t2.field_28 AS [POM Date], 
t2.field_29, 
t2.field_30 AS [Promo Kit], 
t2.field_31 AS [Tip Length], 
t2.field_32 AS [Specialty Fit], 
t2.field_33, 
t2.field_34, 
t2.field_35, 
t2.field_36, 
t2.field_37, 
t2.field_38, 
t2.field_39, 
t2.field_40,
t2.field_18_a AS [Extra Temple A], 
t2.field_18_b AS [Extra Temple B], 
t2.field_18_c AS [Extra Temple C], 
t2.field_18_d AS [Extra Temple D], 
t2.field_18_e AS [Extra Temple E]
FROM  dbo.inv_master t1 INNER JOIN
dbo.inv_master_add t2 ON t1.part_no = t2.part_no
ORDER BY t1.part_no

GO
GRANT REFERENCES ON  [dbo].[Inv_Master_Load_Template_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[Inv_Master_Load_Template_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[Inv_Master_Load_Template_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[Inv_Master_Load_Template_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[Inv_Master_Load_Template_vw] TO [public]
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[28] 4[33] 2[20] 3) )"
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
         Begin Table = "inv_master"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 135
               Right = 258
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "inv_master_add"
            Begin Extent = 
               Top = 7
               Left = 306
               Bottom = 135
               Right = 479
            End
            DisplayFlags = 280
            TopColumn = 51
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 12
         Width = 284
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
         Width = 1200
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1188
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
', 'SCHEMA', N'dbo', 'VIEW', N'Inv_Master_Load_Template_vw', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'Inv_Master_Load_Template_vw', NULL, NULL
GO
