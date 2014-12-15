import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

public class TestSqlite {

	public static void main(String args[]) {
		String tableName="";
		if (args.length == 1) {
			tableName= args[0];
		}
		
		java.sql.Connection c = null;
		Statement stmt = null;
		try {
			Class.forName("org.sqlite.JDBC");
			c = DriverManager.getConnection("jdbc:sqlite:DB_ATHARVA.db");
			c.setAutoCommit(false);
			System.out.println("Opened database successfully");

			stmt = c.createStatement();
			ResultSet rs = null;
			if (args.length == 1) {
				System.out.println("Executing statement for table- "+tableName);
				rs = stmt.executeQuery("SELECT logTraceFile FROM "
						+ tableName + " ;");
				List<String> listOfFiles = new ArrayList<String>();
				while (rs.next()) {
					String logTraceFile = rs.getString("logTraceFile");
					listOfFiles.add(logTraceFile);
				}
				System.out.println("All files are - "+listOfFiles.toString());
				System.exit(0);
			}else{
				System.out.println("Running from runTransactions");
				rs = stmt.executeQuery("SELECT * FROM runTransactions;");
			}

			if(!rs.next()){
				System.out.println("No dat in table currentRunningPool");
				System.exit(0);
			}
			while (rs.next()) {
				int run_id = rs.getInt("run_id");
				String job_id = rs.getString("job_id");
				String job_name = rs.getString("job_name");
				int pid = rs.getInt("pid");
				String start_time = rs.getString("start_time");
				String status = rs.getString("status");
				String compInfo = run_id + "|" + job_id + "|" + job_name + "|"
						+ pid + "|" + start_time + "|" + status;
				System.out.println(compInfo);
			}
			rs.close();
			stmt.close();
			c.close();
		} catch (Exception e) {
			System.err.println(e.getClass().getName() + ": " + e.getMessage());
			System.exit(0);
		}
		System.out.println("Operation done successfully");
	}
}

