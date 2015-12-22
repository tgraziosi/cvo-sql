CREATE TABLE [dbo].[ammasfld]
(
[timestamp] [timestamp] NOT NULL,
[mass_maintenance_id] [dbo].[smSurrogateKey] NOT NULL,
[mass_maintenance_type] [dbo].[smMaintenanceType] NOT NULL,
[field_type] [dbo].[smFieldType] NOT NULL,
[new_value] [dbo].[smFieldData] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ammasfld_ind_0] ON [dbo].[ammasfld] ([mass_maintenance_id], [mass_maintenance_type], [field_type]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammasfld].[mass_maintenance_id]'
GO
GRANT REFERENCES ON  [dbo].[ammasfld] TO [public]
GO
GRANT SELECT ON  [dbo].[ammasfld] TO [public]
GO
GRANT INSERT ON  [dbo].[ammasfld] TO [public]
GO
GRANT DELETE ON  [dbo].[ammasfld] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammasfld] TO [public]
GO
