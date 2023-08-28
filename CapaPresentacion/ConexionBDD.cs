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
            NpgsqlConnection conn = new NpgsqlConnection("Server = silly.db.elephantsql.com; User Id= vyabgmbp; Password= KaCvEtUNH3YFEv64gl4PV8OZ0lhZh8ar; Database= vyabgmbp; Port= 5432");
            public void Conectar()
            {
                conn.Open();
                MessageBox.Show("CONECTADO");
            }
    }
}
