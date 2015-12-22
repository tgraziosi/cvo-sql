SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[adm_artax_vw] as

select 
    tax_code,
    tax_desc,
    tax_included_flag,
    override_flag,
    module_flag,
    isnull(a.tax_connect_flag,0) tax_connect_flag,
    external_tax_code,
    isnull(t.currency_code,'') currency_code
from artax a  (nolock)
join arco c  (nolock) on isnull(a.tax_connect_flag,0) <= isnull(c.tax_connect_flag,0)
left outer join gltcconfig t (nolock) on t.company_id = c.company_id
                                             
GO
GRANT REFERENCES ON  [dbo].[adm_artax_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_artax_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_artax_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_artax_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_artax_vw] TO [public]
GO
