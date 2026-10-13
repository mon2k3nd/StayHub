import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;

public class TestDB {
    public static void main(String[] args) throws Exception {
        Connection conn = DriverManager.getConnection("jdbc:postgresql://localhost:5432/stayhub_db", "postgres", "12345678");
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery("SELECT id, address, address_old, branch_id FROM rooms ORDER BY id DESC LIMIT 15");
        while (rs.next()) {
            System.out.println("id: " + rs.getInt("id") + ", addr: " + rs.getString("address") + ", addr_old: " + rs.getString("address_old") + ", branch: " + rs.getInt("branch_id"));
        }
    }
}
