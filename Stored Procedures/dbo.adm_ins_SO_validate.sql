SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
          
          
          
          
          
          
          
          
           
          
CREATE procedure [dbo].[adm_ins_SO_validate]          
          
          
          
          
          
as          
          
          
          
 INSERT INTO #ewerror          
 (module_id,err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4800, temp.SONumber, temp.SONumber, 0            
 FROM CVO_TempSO temp           
 INNER JOIN CVO_TempSO temp2 ON temp.key_table <> temp2.key_table AND temp.SONumber = temp2.SONumber          
          
          
 INSERT INTO #ewerror          
 (module_id,err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1001, temp.SONumber, temp.SoldTo, 0           
 FROM CVO_TempSO temp           
 LEFT JOIN adm_cust adm ON temp.SoldTo = adm.customer_code           
 WHERE adm.customer_code IS NULL         --fzambada rev4  
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1100, temp.SONumber, temp.ShipTo, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN adm_shipto l ON temp.ShipTo = l.ship_to_code AND temp.SoldTo = l.customer_code          
 WHERE l.ship_to_code IS NULL AND temp.ShipTo IS NOT NULL AND temp.ShipTo <> ''           
and temp.shipto not like 'G%'	--fzambada go live
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info,source, sequence_id)          
 SELECT DISTINCT 19000,1200, temp.SONumber, temp.Carrier, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arshipv ar ON temp.Carrier = ar.ship_via_code           
 WHERE ar.ship_via_code IS NULL           
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1300, temp.SONumber, temp.Fob, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arfob adm ON temp.Fob = adm.fob_code          
 WHERE adm.fob_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1500, temp.SONumber, temp.Terms, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arterms adm ON temp.Terms = adm.terms_code          
 WHERE adm.terms_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1400, temp.SONumber, temp.Tax, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN adm_artax_vw adm ON temp.Tax = adm.tax_code           
 WHERE adm.tax_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1600, temp.SONumber, temp.PostingCode, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN araccts adm ON temp.PostingCode = adm.posting_code           
 WHERE adm.posting_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2100, temp.SONumber, temp.SONumber, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 WHERE tempd.SONumber IS NULL          
          
          
          
          
          
          
          
          
          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2400, temp.SONumber, temp.Currency, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN glcurr_vw vw ON temp.Currency = vw.currency_code          
 WHERE vw.currency_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2500, temp.SONumber, temp.SalesPerson, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arsalesp b ON temp.SalesPerson = b.salesperson_code          
 WHERE b.salesperson_code IS NULL AND temp.Poaction = 1 AND temp.SalesPerson <> ''          
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1700, temp.SONumber, temp.UserStatus, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN so_usrstat b ON temp.UserStatus = b.user_stat_code AND b.status_code = 'N'          
 WHERE b.user_stat_code IS NULL AND temp.UserStatus <> ''          
          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2700, temp.SONumber, temp.Blanket, 0          
 FROM CVO_TempSO temp          
 WHERE temp.Blanket NOT IN ('Y', 'N')          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2800, temp.SONumber, temp.BlanketFrom, 0          
 FROM CVO_TempSO temp          
 WHERE temp.BlanketFrom IS NULL          
 AND temp.Blanket = 'Y'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 2900, temp.SONumber, temp.BlanketTo, 0          
 FROM CVO_TempSO temp          
 WHERE temp.BlanketTo IS NULL          
 AND temp.Blanket = 'Y'           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 1800, temp.SONumber, temp.BlanketAmount, 0          
 FROM CVO_TempSO temp          
 WHERE ISNULL(temp.BlanketAmount, 0) = 0           
 AND temp.Blanket = 'Y' AND ISNULL(temp.BlanketAmount, 0) = 0          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3000, temp.SONumber, temp.Location, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN locations b ON temp.Location = b.location          
 WHERE b.location IS NULL           
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3100, temp.SONumber, temp.BackOrder, 0          
 FROM CVO_TempSO temp          
 WHERE temp.BackOrder NOT IN ('0', '1', '2')           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3200, temp.SONumber, temp.Category, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN so_usrcateg b ON temp.Category = b.category_code          
 WHERE b.category_code IS NULL AND temp.Category <> ''          
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3300, temp.SONumber, temp.SOPriority, 0          
 FROM CVO_TempSO temp          
 WHERE temp.SOPriority NOT IN ('1','2','3','4','5','6','7','8','9','')          
 AND temp.SOPriority IS NOT NULL          
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3400, temp.SONumber, temp.Fowarder, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arfwdr vw ON temp.Fowarder = vw.kys          
 WHERE vw.kys IS NULL AND temp.Fowarder <> ''          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3500, temp.SONumber, temp.FreightTo, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN arfrt_to vw ON temp.FreightTo = vw.kys          
 WHERE vw.kys IS NULL AND temp.FreightTo <> ''           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 3600, temp.SONumber, temp.FreightType, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN freight_type vw ON temp.FreightType = vw.kys          
 WHERE vw.kys IS NULL AND temp.FreightType <> ''          
          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 4600, temp.SONumber, temp.Hold, 0          
 FROM CVO_TempSO temp          
 LEFT JOIN adm_oehold adm ON temp.Hold = adm.hold_code          
 WHERE adm.hold_code IS NULL AND temp.Hold IS NOT NULL           
 AND temp.Hold <> ''          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5100, temp.SONumber, temp.Phone, 0          
 FROM CVO_TempSO temp          
 WHERE ISNUMERIC(temp.Phone) = 0          
          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5200, temp.order_no, temp.payment_code, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 LEFT JOIN arpymeth ar ON temp.payment_code = ar.payment_code          
 WHERE ar.payment_code IS NULL AND temp.payment_code IS NOT NULL          
 AND temph.Consolidate = 0          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6400, temp.order_no, temph.Consolidate, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN orders ord ON temp.order_no = ord.order_no          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 AND ISNULL(temph.Consolidate, ord.consolidate_flag) = 1          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5300, temp.order_no, temp.amt_payment, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temp.amt_payment < 0 AND temph.Consolidate = 0           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5400, temp.order_no, temp.amt_disc_taken, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temp.amt_disc_taken < 0 AND temph.Consolidate = 0           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5500, temp.order_no, temp.salesperson, 0          
 FROM CVO_TempSOCO temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 LEFT JOIN arsalesp ar ON temp.salesperson = ar.salesperson_code          
 WHERE ar.salesperson_code IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5600, temp.order_no, temp.sales_comm, 0          
 FROM CVO_TempSOCO temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temp.sales_comm < 0           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5700, temp.order_no, 0, 0          
 FROM CVO_TempSOCO temp          
 INNER JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temp.split_flag > 1           
 AND (temp.percent_flag > 1           
      OR (temp.exclusive_flag > 1))          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5800, temp.order_no, 0, 0          
 FROM CVO_TempSOPAY temp          
 LEFT JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temph.SONumber IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 5900, temp.order_no, 0, 0          
 FROM CVO_TempSOCO temp          
 LEFT JOIN CVO_TempSO temph ON temp.order_no = temph.SONumber          
 WHERE temph.SONumber IS NULL           
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6500, temp.order_no, 0, 0          
 FROM CVO_TempSOCO temp          
 WHERE temp.display_line IS NULL          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6600, temp.order_no, 0, 0          
 FROM CVO_TempSOCO temp          
 INNER JOIN CVO_TempSOCO temp2 ON temp.key_table <> temp2.key_table           
 AND temp.order_no = temp2.order_no          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6000, temp.order_no, temp.prompt2_inp, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN CVO_TempSO  temph ON temp.order_no = temph.SONumber          
 INNER JOIN icv_cctype icv (NOLOCK) ON temp.payment_code = icv.payment_code          
 WHERE len(temp.prompt2_inp) <> icv.creditcard_length            
           
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6100, temp.order_no, temp.prompt2_inp, 0          
 FROM CVO_TempSOPAY temp          
 INNER JOIN CVO_TempSO  temph ON temp.order_no = temph.SONumber          
 INNER JOIN icv_cctype icv (NOLOCK) ON temp.payment_code = icv.payment_code          
 WHERE cast(temp.prompt2_inp as varchar(16)) NOT like cast(icv.creditcard_prefix as varchar(16) ) + '%'          
          
           
          
           
  INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6800, temp.SONumber, temp.MultipleShip , 0           
 FROM CVO_TempSO temp          
 WHERE ISNULL(temp.MultipleShip, 'N') <> 'N'          
 AND ISNULL(temp.Blanket, 'N') = 'Y'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 6900, temp.SONumber, tempd.ShipTo, 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN adm_shipto l ON tempd.ShipTo = l.ship_to_code AND temp.SoldTo = l.customer_code          
 WHERE l.ship_to_code IS NULL AND temp.ShipTo IS NOT NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 7000, temp.SONumber, tempd.Fob, 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN arfob adm ON tempd.Fob = adm.fob_code          
 WHERE adm.fob_code IS NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 7100, temp.SONumber, tempd.Routing, 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN arshipv adm ON adm.ship_via_code = tempd.Routing          
 WHERE adm.ship_via_code IS NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 7200, temp.SONumber, tempd.Forwarder , 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN arfwdr adm ON adm.kys  = tempd.Forwarder          
 WHERE adm.kys IS NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 7300, temp.SONumber, tempd.ShipToRegion , 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN arterr adm ON adm.territory_code  = tempd.ShipToRegion          
 WHERE adm.territory_code IS NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)       
 SELECT DISTINCT 19000, 7400, temp.SONumber, tempd.DestZone , 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOD tempd ON temp.SONumber = tempd.SONumber          
 LEFT JOIN arzone adm ON adm.zone_code  = tempd.DestZone          
 WHERE adm.zone_code IS NULL           
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
 INSERT INTO #ewerror          
 (module_id, err_code, info, source, sequence_id)          
 SELECT DISTINCT 19000, 7500, temp.SONumber, temp.SONumber, 0          
 FROM CVO_TempSO temp          
 INNER JOIN CVO_TempSOPAY tempd ON temp.SONumber = tempd.order_no          
 AND ISNULL(temp.MultipleShip, 'N') <> 'N'          
          
          
          
/**/ 
GO
GRANT EXECUTE ON  [dbo].[adm_ins_SO_validate] TO [public]
GO
