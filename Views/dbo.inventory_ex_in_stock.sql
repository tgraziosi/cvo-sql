SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[inventory_ex_in_stock]
AS
SELECT	l.part_no, l.location, m.upc_code, l.bin_no, m.description, l.std_cost, l.std_ovhd_dolrs, l.std_util_dolrs, 

		CASE WHEN (m.status = 'C' OR m.status = 'V') THEN 0 
			ELSE (l.in_stock + l.issued_mtd + p.produced_mtd - p.usage_mtd - s.sales_qty_mtd + r.recv_mtd + x.xfer_mtd) END AS 'AllStock', 

		ISNULL(z.qty, 0) AS 'AllNonAlloc', 

		ISNULL ((SELECT SUM(qty) AS Expr1   FROM dbo.lot_bin_stock 
                 WHERE bin_no IN ('rr wty', 'rr scrap', 'w01a-03-02') AND part_no = l.part_no and location=l.location), 0) AS 'NonAllocNonStock',

		ISNULL ((SELECT SUM(qty) AS Expr9  FROM dbo.lot_bin_stock 
                 WHERE bin_no NOT IN ('rr wty', 'rr scrap', 'w01a-03-02') AND part_no = l.part_no and location=l.location), 0) AS 'in_stock_DRP',

		l.min_stock, l.max_stock, l.min_order, s.qty_alloc, s.commit_ed, r.po_on_order, m.vendor, l.rank_class, 
		m.category, m.type_code, p.sch_alloc, p.sch_date, s.last_order_qty, r.last_recv_date, 
        l.lead_time, l.status, m.freight_class, m.cubic_feet, m.weight_ea, s.oe_on_order, s.oe_order_date, 
		ISNULL(pr.price_a, 0) AS price_a, m.labor, p.qty_scheduled, m.uom, ISNULL(pr.promo_type, 'N') AS promo_type,
		ISNULL(pr.promo_rate, 0) AS promo_rate, pr.promo_date_expires, pr.promo_date_entered, m.account, m.comm_type, 
		l.qty_year_end, l.qty_month_end, l.qty_physical, l.entered_who, l.entered_date, m.void, 
		m.void_who, m.void_date, l.std_cost AS Expr1, l.std_labor, l.std_direct_dolrs, l.std_ovhd_dolrs AS Expr2, l.std_util_dolrs AS Expr3, 
		m.taxable, l.setup_labor, m.lb_tracking, m.rpt_uom, l.freight_unit, m.qc_flag, m.conv_factor, 
		CASE WHEN l.note IS NULL OR ltrim(l.note) = '' THEN m.note ELSE l.note END AS note, l.cycle_date, m.cycle_type, 
		p.hold_mfg, s.hold_ord, r.hold_rcv, x.hold_xfr, m.inv_cost_method, m.buyer, l.acct_code, m.allow_fractions, 
		m.tax_code, m.obsolete, m.serial_flag, l.eoq, x.transit, m.cfg_flag, m.web_saleable_flag, l.dock_to_stock, 
		l.order_multiple, l.po_uom, l.so_uom, m.non_sellable_flag, ISNULL(l.qc_qty, 0) AS qc_qty, x.commit_ed AS xfer_commit_ed, 
		ISNULL(mtd.issued_qty, 0) AS issued_mtd, ISNULL(mtd.produced_qty, 0) AS produced_mtd, ISNULL(mtd.usage_qty, 0) AS usage_mtd, 
		ISNULL(mtd.sales_qty, 0) AS sales_qty_mtd, ISNULL(mtd.sales_amt, 0) AS sales_amt_mtd, ISNULL(mtd.recv_qty, 0) AS recv_mtd, 
		ISNULL(mtd.xfer_qty, 0) AS xfer_mtd, ISNULL(ytd.issued_qty, 0) AS issued_ytd, ISNULL(ytd.produced_qty, 0) AS produced_ytd, 
		ISNULL(ytd.usage_qty, 0) AS usage_ytd, ISNULL(ytd.sales_qty, 0) AS sales_qty_ytd, ISNULL(ytd.sales_amt, 0) AS sales_amt_ytd, 
		ISNULL(ytd.recv_qty, 0) AS recv_ytd, ISNULL(ytd.xfer_qty, 0) AS xfer_ytd, loc.organization_id
FROM         dbo.inv_list AS l WITH (nolock) INNER JOIN
                      dbo.inv_master AS m WITH (nolock) ON m.part_no = l.part_no INNER JOIN
                      dbo.inv_produce AS p WITH (nolock) ON p.part_no = m.part_no AND p.location = l.location INNER JOIN
                      dbo.inv_sales AS s WITH (nolock) ON s.part_no = m.part_no AND s.location = l.location INNER JOIN
                      dbo.inv_xfer AS x WITH (nolock) ON x.part_no = m.part_no AND x.location = l.location INNER JOIN
                      dbo.inv_recv AS r WITH (nolock) ON r.part_no = m.part_no AND r.location = l.location INNER JOIN
                      dbo.glco AS g WITH (nolock) ON 1 = 1 LEFT OUTER JOIN
                      dbo.part_price AS pr WITH (nolock) ON pr.part_no = m.part_no AND pr.curr_key = g.home_currency INNER JOIN
                          (SELECT     period
                            FROM          dbo.adm_inv_mtd_cal_f() AS adm_inv_mtd_cal_f_1) AS c_1(period) ON 1 = 1 LEFT OUTER JOIN
                      dbo.adm_inv_mtd AS mtd WITH (nolock) ON mtd.part_no = l.part_no AND mtd.location = l.location AND mtd.period = c_1.period LEFT OUTER JOIN
                          (SELECT     m.part_no, m.location, SUM(m.issued_qty) AS Expr1, SUM(m.produced_qty) AS Expr2, SUM(m.usage_qty) AS Expr3, SUM(m.sales_qty) 
                                                   AS Expr4, SUM(m.sales_amt) AS Expr5, SUM(m.recv_qty) AS Expr6, SUM(m.xfer_qty) AS Expr7
                            FROM          dbo.adm_inv_mtd AS m WITH (nolock) CROSS JOIN
                                                   dbo.adm_inv_mtd_cal_f() AS c
                            WHERE      (m.period BETWEEN c.fiscal_start AND c.period)
                            GROUP BY m.part_no, m.location) AS ytd(part_no, location, issued_qty, produced_qty, usage_qty, sales_qty, sales_amt, recv_qty, xfer_qty) ON 
                      ytd.part_no = l.part_no AND ytd.location = l.location INNER JOIN
                      dbo.locations AS loc WITH (nolock) ON l.location = loc.location 
					  LEFT OUTER JOIN
                      -- dbo.f_get_excluded_bins(1) AS z ON l.part_no = z.part_no AND l.location = z.location
					  f_get_excluded_bins_1_vw AS z ON l.part_no = z.part_no AND l.location = z.location

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
         Begin Table = "l"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 121
               Right = 226
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "m"
            Begin Extent = 
               Top = 6
               Left = 264
               Bottom = 121
               Right = 452
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "p"
            Begin Extent = 
               Top = 6
               Left = 490
               Bottom = 121
               Right = 642
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "s"
            Begin Extent = 
               Top = 6
               Left = 680
               Bottom = 121
               Right = 833
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "x"
            Begin Extent = 
               Top = 6
               Left = 871
               Bottom = 121
               Right = 1023
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "r"
            Begin Extent = 
               Top = 6
               Left = 1061
               Bottom = 121
               Right = 1214
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "g"
            Begin Extent = 
               Top = 126
               Left = 38
               Bottom = 241
               Right = 244
            End
            DisplayFlags = 280
            TopColumn = 0
         End
    ', 'SCHEMA', N'dbo', 'VIEW', N'inventory_ex_in_stock', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'     Begin Table = "pr"
            Begin Extent = 
               Top = 126
               Left = 282
               Bottom = 241
               Right = 472
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c_1"
            Begin Extent = 
               Top = 126
               Left = 510
               Bottom = 196
               Right = 662
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "mtd"
            Begin Extent = 
               Top = 126
               Left = 700
               Bottom = 241
               Right = 852
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "ytd"
            Begin Extent = 
               Top = 126
               Left = 890
               Bottom = 241
               Right = 1042
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "loc"
            Begin Extent = 
               Top = 126
               Left = 1080
               Bottom = 241
               Right = 1276
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "z"
            Begin Extent = 
               Top = 198
               Left = 510
               Bottom = 313
               Right = 662
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
', 'SCHEMA', N'dbo', 'VIEW', N'inventory_ex_in_stock', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'inventory_ex_in_stock', NULL, NULL
GO
