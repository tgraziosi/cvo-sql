SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_open_po_cmi_epc_sp]
AS 

SET NOCOUNT ON;

SELECT DISTINCT
       ISNULL(ap.vendor_code, ccv.supplier) vendor,
       wsinfo.shipment_number,
       wsinfo.WS_PO_NUM,
       ccv.Collection,
       ccv.model,
       ccv.RES_type,
       ccv.ColorGroupCode,
       ccv.eye_size,
       ccv.release_date,
       ccv.frame_cost,
       CASE WHEN wsinfo.shipment_number = 'frame-1' THEN ccv.ws_ship1_qty
           WHEN wsinfo.shipment_number = 'frame-2' THEN ccv.ws_ship2_qty
           WHEN wsinfo.shipment_number = 'frame-3' THEN ccv.ws_ship3_qty ELSE 0
       END AS qty_open,
       CASE WHEN wsinfo.shipment_number = 'frame-1' THEN ccv.ws_ship1_qty
           WHEN wsinfo.shipment_number = 'frame-2' THEN ccv.ws_ship2_qty
           WHEN wsinfo.shipment_number = 'frame-3' THEN ccv.ws_ship3_qty ELSE 0
       END * ccv.frame_cost AS ext_cost_open,
       wsinfo.ship_date,
       ccv.sku,
       'CMI' source
FROM

    dbo.cvo_cmi_catalog_view AS ccv (NOLOCK)

    JOIN
    (
    SELECT w.model_id,
           sh.shipment_number,
           CAST(latest_ws.w_id AS VARCHAR(10)) WS_PO_NUM,
           CASE sh.id WHEN 1 THEN w.ship1_ship WHEN 2 THEN w.ship2_ship WHEN 3 THEN w.ship3_ship ELSE NULL END AS ship_date
    FROM
    (
    SELECT model_id,
           MAX(id) w_id
    FROM dbo.cvo_cmi_worksheet_data
    GROUP BY model_id
    ) latest_ws
        JOIN dbo.cvo_cmi_worksheet_data w WITH (NOLOCK)
            ON w.id = latest_ws.w_id
        JOIN dbo.cvo_cmi_catalog_view AS ccv
            ON ccv.model_id = w.model_id

        CROSS JOIN
        (
        SELECT 1 id,
               'FRAME-1' shipment_number
        UNION
        SELECT 2,
               'FRAME-2'
        UNION
        SELECT 3,
               'FRAME-3'
        ) sh
    WHERE ccv.sku IS NULL
          AND (ccv.ws_ship1_qty + ccv.ws_ship2_qty + ccv.ws_ship3_qty) > 0
    ) wsinfo
        ON wsinfo.model_id = ccv.model_id
    LEFT OUTER JOIN dbo.apmaster ap (NOLOCK)
        ON ap.address_name = ccv.supplier

WHERE ccv.sku IS NULL
      AND ccv.release_date > GETDATE()
	  AND (ccv.ws_ship1_qty + ccv.ws_ship2_qty + ccv.ws_ship3_qty) > 0


UNION ALL

SELECT av.vendor_no,
       av.category,
       CAST(av.po_key AS VARCHAR(10)),
       i.category brand,
       ia.field_2 model,
       i.type_code res_type,
       ia.category_5 colorgroupcode,
       ia.field_17 eye_size,
       ia.field_26 release_date,
       av.unit_cost,
       -- av.ext_cost ,
       av.qty_open,
       av.ext_cost_open,
       av.departure_date,
       av.part_no,
       'EPC' source
FROM dbo.cvo_adpol_vw AS av
    JOIN dbo.inv_master i (NOLOCK)
        ON i.part_no = av.part_no
    JOIN dbo.inv_master_add ia (NOLOCK)
        ON ia.part_no = i.part_no
WHERE av.status LIKE '%O%'
      AND av.location = '001'
      AND av.qty_open <> 0;

GO
GRANT EXECUTE ON  [dbo].[cvo_open_po_cmi_epc_sp] TO [public]
GO
