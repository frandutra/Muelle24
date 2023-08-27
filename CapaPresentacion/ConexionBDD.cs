using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using Npgsql;

namespace CapaPresentacion
{
    internal class ConexionBDD
    {
            NpgsqlConnection conn = new NpgsqlConnection("Server = silly.db.elephantsql.com; User Id= vuxgyuvc; Password= 9wI083U3JMWjXQ_cdYGTedhOjpdvbXSM; Database= vuxgyuvc; Port= 5432");
            public void Conectar()
            {
                conn.Open();
                MessageBox.Show("CONECTADO");
            }
    }
}
