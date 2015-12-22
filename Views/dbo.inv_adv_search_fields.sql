SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[inv_adv_search_fields] 
AS 
SELECT 
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'datetime_1_t') datetime_1_l, CAST(NULL AS DATETIME)  datetime_1_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'datetime_2_t') datetime_2_l, CAST(NULL AS DATETIME)  datetime_2_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'category_1_t') category_1_l, SPACE(15)  category_1_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'category_2_t') category_2_l, SPACE(15)  category_2_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'category_3_t') category_3_l, SPACE(15)  category_3_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'category_4_t') category_4_l, SPACE(15)  category_4_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'category_5_t') category_5_l, SPACE(15)  category_5_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_1_t'   ) field_1_l,    SPACE(40)  field_1_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_2_t'   ) field_2_l,    SPACE(40)  field_2_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_3_t'   ) field_3_l,    SPACE(40)  field_3_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_4_t'   ) field_4_l,    SPACE(40)  field_4_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_5_t'   ) field_5_l,    SPACE(40)  field_5_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_6_t'   ) field_6_l,    SPACE(40)  field_6_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_7_t'   ) field_7_l,    SPACE(40)  field_7_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_8_t'   ) field_8_l,    SPACE(40)  field_8_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_9_t'   ) field_9_l,    SPACE(40)  field_9_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_10_t'  ) field_10_l,   SPACE(40)  field_10_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_11_t'  ) field_11_l,   SPACE(40)  field_11_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_12_t'  ) field_12_l,   SPACE(40)  field_12_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_13_t'  ) field_13_l,   SPACE(40)  field_13_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_14_t'  ) field_14_l,   SPACE(255) field_14_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_15_t'  ) field_15_l,   SPACE(255) field_15_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'field_16_t'  ) field_16_l,   SPACE(255) field_16_t,
       (SELECT field_text  FROM inv_master_add_fields (NOLOCK) WHERE field_name = 'long_descr_t') long_descr_l, SPACE(100) long_descr_t,
       '' 	  AS cbx_items, 	'' 	  AS cbx_inactive,  	'' 	  AS cbx_void, 		'' 	   AS cbx_web_sale,  
       '' 	  AS cbx_make,		'' 	  AS cbx_qty_avail, 	'' 	  AS cbx_obsolete, 	'' 	   AS cbx_non_sellable,                      
        SPACE(30) AS part_t,           	SPACE(10) AS loc_t,        	SPACE(10) AS group_t,          	SPACE(12)  AS vendor_t,   
        SPACE(10) AS res_type_t,	SPACE(20) AS UPC_t,           	SPACE(30) AS drawing_t,        	SPACE(255) AS descr_t 

GO
GRANT REFERENCES ON  [dbo].[inv_adv_search_fields] TO [public]
GO
GRANT SELECT ON  [dbo].[inv_adv_search_fields] TO [public]
GO
GRANT INSERT ON  [dbo].[inv_adv_search_fields] TO [public]
GO
GRANT DELETE ON  [dbo].[inv_adv_search_fields] TO [public]
GO
GRANT UPDATE ON  [dbo].[inv_adv_search_fields] TO [public]
GO
