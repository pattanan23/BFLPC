const express = require('express');
const bodyParser = require('body-parser');
const sql = require('mssql');
const cors = require('cors');

const app = express();
const port = 5000;

app.use(bodyParser.json());
app.use(express.json())

// ตั้งค่า CORS อย่างชัดเจน
// Set CORS explicitly
const corsOptions = { 
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type']
};
app.use(cors(corsOptions));

// ตั้งค่าการเชื่อมต่อ SQL Server
// Set up SQL Server connection
const dbConfig = {
  user: 'sa',
  password: 'pack73180',
  server: 'DESKTOP-D4JMUA1',
  port: 59432,
  database: 'PalletSlip',
  options: {
    encrypt: false,
    trustServerCertificate: true
  }
};

// API สำหรับ Login
// API for Login
app.post('/login', async (req, res) => {
  const { username, password, department } = req.body;

  try {
    await sql.connect(dbConfig);
    const result = await sql.query`
      SELECT * FROM LoginID
      WHERE Username = ${username}
        AND Password = ${password}
        AND Department = ${department}`;

    if (result.recordset.length > 0) {
      res.json({ status: 'success', user: result.recordset[0] });
    } else {
      res.json({ status: 'fail', message: 'Incorrect information' });
    }
  } catch (err) {
    console.error('SQL error', err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  } finally {
    if (sql.connected) await sql.close();
  }
});


// API สำหรับส่งฟอร์มข้อมูล
// API for sending form data
app.post('/submit-form', async (req, res) => {
  try {
    await sql.connect(dbConfig);
    const {
      FGCode, LotNo, PDLine, Packing, BagsNo, BagsWeight,
      Type, MFGDate, Expiry, Staff, Barcode, DocumentNo, FormulaName
    } = req.body;

    const bagsNo = isNaN(parseInt(BagsNo)) ? 0 : parseInt(BagsNo);
    const bagsWeight = isNaN(parseFloat(BagsWeight)) ? 0 : parseFloat(BagsWeight);
    const TotalWeight = bagsNo * bagsWeight;
    const today = new Date();

    const slipQuery = `
      SELECT MAX(Slip_No) AS MaxSNo 
      FROM PalletSlip 
      WHERE Lot_No = @LotNo AND Formula_Code = @FGCode`;

    const slipRequest = new sql.Request()
      .input('LotNo', sql.NVarChar(50), LotNo)
      .input('FGCode', sql.NVarChar(50), FGCode);

    const slipResult = await slipRequest.query(slipQuery);
    const maxSNo = slipResult.recordset[0].MaxSNo;
    const newSlipNo = maxSNo === null ? 1 : parseInt(maxSNo) + 1;

    const insertQuery = `
      INSERT INTO PalletSlip (
        Slip_No, [Date], Document_No, Pack_No, Formula_Code, Formula_Name,
        PD_Line, Lot_No, Pack_Type, Bag_Weight, Total_Bag_No,
        TotalWeight, MFG_Date, Expiry_Date, Staff_Name, Bar_Code
      ) VALUES (
        @Slip_No, @Date, @Document_No, @Pack_No, @Formula_Code, @Formula_Name,
        @PD_Line, @Lot_No, @Pack_Type, @Bag_Weight, @Total_Bag_No,
        @TotalWeight, @MFG_Date, @Expiry_Date, @Staff_Name, @Bar_Code
      )`;

    const request = new sql.Request()
      .input('Slip_No', sql.Int, newSlipNo)
      .input('Date', sql.Date, today)
      .input('Document_No', sql.NVarChar(50), DocumentNo)
      .input('Pack_No', sql.NVarChar(50), Packing)
      .input('Formula_Code', sql.NVarChar(50), FGCode)
      .input('Formula_Name', sql.NVarChar(50), FormulaName)
      .input('PD_Line', sql.NVarChar(50), PDLine)
      .input('Lot_No', sql.NVarChar(50), LotNo)
      .input('Pack_Type', sql.NVarChar(50), Type)
      .input('Bag_Weight', sql.NVarChar(50), bagsWeight.toString())
      .input('Total_Bag_No', sql.NVarChar(50), bagsNo.toString())
      .input('TotalWeight', sql.NVarChar(50), TotalWeight.toString())
      .input('MFG_Date', sql.NVarChar(50), MFGDate)
      .input('Expiry_Date', sql.NVarChar(50), Expiry)
      .input('Staff_Name', sql.NVarChar(50), Staff)
      .input('Bar_Code', sql.NVarChar(50), Barcode);

    await request.query(insertQuery);
    res.json({ status: 'success', message: 'Data inserted' });
  } catch (err) {
    console.error('SQL error submitting form', err);
    res.status(500).json({ status: 'error', message: 'Submit failed' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API สำหรับสถิติการอนุมัติ (Pie chart)
// API for approval statistics (Pie chart)
app.get('/approval-stats', async (req, res) => {
  try {
    await sql.connect(dbConfig);
    const result = await sql.query(`
      SELECT 
        COUNT(CASE WHEN Approved = 'yes' THEN 1 END) AS accepted,
        COUNT(CASE WHEN Approved IS NULL THEN 1 END) AS pending,
        COUNT(CASE WHEN Approved = 'no' THEN 1 END) AS rejected
      FROM PalletSlip
    `);
    res.json({ status: 'success', data: result.recordset[0] });
  } catch (err) {
    console.error('Error fetching approval stats:', err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API สำหรับดึงข้อมูล PalletSlip
// API for fetching PalletSlip data
app.get('/palletslip', async (req, res) => {
  try {
    await sql.connect(dbConfig);
    const result = await sql.query('SELECT * FROM PalletSlip ORDER BY [Date] DESC');
    res.json({ status: 'success', data: result.recordset });
  } catch (err) {
    console.error('Error fetching data', err);
    res.status(500).json({ status: 'error', message: 'Failed to fetch data' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API สำหรับอัปเดตข้อมูล PalletSlip
// API for updating PalletSlip data.
app.post('/update-slip', async (req, res) => {
  try {
    const {
      Slip_No, Document_No, Pack_No, Formula_Code, Formula_Name,
      PD_Line, Lot_No, Type, Bag_Weight, Total_Bag_No,
      TotalWeight, MFG_Date, Expiry_Date, Staff_Name, Bar_Code
    } = req.body;

    await sql.connect(dbConfig);

    const query = `
      UPDATE PalletSlip SET
        Document_No = @Document_No,
        Pack_No = @Pack_No,
        Formula_Code = @Formula_Code,
        Formula_Name = @Formula_Name,
        PD_Line = @PD_Line,
        Lot_No = @Lot_No,
        Pack_Type = @Pack_Type,
        Bag_Weight = @Bag_Weight,
        Total_Bag_No = @Total_Bag_No,
        TotalWeight = @TotalWeight,
        MFG_Date = @MFG_Date,
        Expiry_Date = @Expiry_Date,
        Staff_Name = @Staff_Name,
        Bar_Code = @Bar_Code
      WHERE Slip_No = @Slip_No
    `;

    const request = new sql.Request()
      .input('Slip_No', sql.Int, Slip_No)
      .input('Document_No', sql.NVarChar(50), Document_No)
      .input('Pack_No', sql.NVarChar(50), Pack_No)
      .input('Formula_Code', sql.NVarChar(50), Formula_Code)
      .input('Formula_Name', sql.NVarChar(50), Formula_Name)
      .input('PD_Line', sql.NVarChar(50), PD_Line)
      .input('Lot_No', sql.NVarChar(50), Lot_No)
      .input('Pack_Type', sql.NVarChar(50), Type)
      .input('Bag_Weight', sql.NVarChar(50), Bag_Weight.toString())
      .input('Total_Bag_No', sql.NVarChar(50), Total_Bag_No.toString())
      .input('TotalWeight', sql.NVarChar(50), TotalWeight.toString())
      .input('MFG_Date', sql.NVarChar(50), MFG_Date)
      .input('Expiry_Date', sql.NVarChar(50), Expiry_Date)
      .input('Staff_Name', sql.NVarChar(50), Staff_Name)
      .input('Bar_Code', sql.NVarChar(50), Bar_Code);

    await request.query(query);
    res.json({ status: 'success', message: 'Data updated successfully' });
  } catch (err) {
    console.error('SQL error updating form', err);
    res.status(500).json({ status: 'error', message: 'Update failed' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API ค้นหาข้อมูลจาก Barcode จาก PalletSlip
// API search data from Barcode from PalletSlip
app.get('/search-barcode', async (req, res) => {
  const { barcode } = req.query;
  try {
    await sql.connect(dbConfig);

    // ข้อมูลจาก PalletSlip
    const result1 = await sql.query`
      SELECT Bar_Code, Slip_No, Document_No, Formula_Name, Formula_Code, Lot_No, 
             Pack_No, Pack_Type, Bag_Weight, Total_Bag_No
      FROM PalletSlip WHERE Bar_Code = ${barcode}
    `;

    // ข้อมูลจาก Checker
    const result2 = await sql.query`
  SELECT TOP 1 Approved, Rejected, Comment, Name
  FROM Checker WHERE Bar_Code = ${barcode}
  ORDER BY Date DESC, Time DESC
`;   
    if (result1.recordset.length > 0) {
      const combinedData = { ...result1.recordset[0], ...(result2.recordset[0] || {}) };
      res.json({ status: 'success', data: [combinedData] });
    } else {
      res.json({ status: 'not_found', message: 'No information found' });
    }
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API สำหรับส่งข้อมูลการอนุมัติ บันทึกข้อมูลลง Checker + อัปเดต PalletSlip
// API for sending approval data, saving data to Checker + updating PalletSlip
app.post('/submit-status', async (req, res) => {
  const { slip_no, date, time, bar_code, comment, approved, rejected, name } = req.body;

  if (
    !bar_code?.trim() ||
    !name?.trim() ||
    !['yes', 'no'].includes(approved) ||
    !['yes', 'no'].includes(rejected)
  ) {
    return res.status(400).json({ status: 'error', message: 'Incomplete or incorrect information' });
  }

  try {
    await sql.connect(dbConfig);

    // ตรวจสอบว่า Bar_Code นี้มีอยู่ใน Checker หรือยัง
    const result = await sql.query`
      SELECT * FROM Checker WHERE Bar_Code = ${bar_code}
    `;

    if (result.recordset.length > 0) {
      // มีอยู่แล้ว → UPDATE
      await sql.query`
        UPDATE Checker
        SET 
          Slip_No = ${slip_no},
          Date = ${date},
          Time = ${time},
          Comment = ${comment || null},
          Approved = ${approved},
          Rejected = ${rejected},
          Name = ${name}
        WHERE Bar_Code = ${bar_code}
      `;
    } else {
      // ยังไม่มี → INSERT
      await sql.query`
        INSERT INTO Checker (Slip_No, Date, Time, Bar_Code, Comment, Approved, Rejected, Name)
        VALUES (${slip_no}, ${date}, ${time}, ${bar_code}, ${comment || null}, ${approved}, ${rejected}, ${name})
      `;
    }

    // ✅ เพิ่มตรงนี้: อัปเดตตาราง PalletSlip ให้ตรงกับ Checker
    await sql.query`
      UPDATE PalletSlip
      SET 
        Approved = ${approved},
        Rejected = ${rejected}
      WHERE Bar_Code = ${bar_code}
    `;

    res.json({ status: 'success', message: 'Data has been recorded successfully.' });

  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ status: 'error', message: 'An error occurred in the system.' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// API ค้นหาข้อมูลจาก Barcode จาก PalletSlip และ Loader เฉพาะที่ approved แล้ว
// API finds data from Barcode from PalletSlip and Loader only that are approved.
app.get('/search-barcode-loader', async (req, res) => {
  const { barcode } = req.query;
  try {
    await sql.connect(dbConfig);

    // ตรวจสอบสถานะใน Checker ก่อน
    const checkerResult = await sql.query`
      SELECT approved, rejected 
      FROM Checker 
      WHERE bar_code = ${barcode}
    `;

    // ไม่มีใน Checker หรือยังไม่ approved → ไม่อนุญาตให้ดู
    if (
      checkerResult.recordset.length === 0 ||
      checkerResult.recordset[0].approved !== 'yes' ||
      checkerResult.recordset[0].rejected === 'yes'
    ) {
      return res.json({
        status: 'not_found',
        message: 'It has not been approved or rejected.',
      });
    }

    // ดึงข้อมูลจาก PalletSlip
    const result1 = await sql.query`
      SELECT Bar_Code, Slip_No, Document_No, Formula_Name, Formula_Code, Lot_No, 
             Pack_No, Pack_Type, Bag_Weight, Total_Bag_No
      FROM PalletSlip WHERE Bar_Code = ${barcode}
    `;

    // ดึงข้อมูลจาก Loader
    const result2 = await sql.query`
      SELECT TOP 1 Check_In, Check_Out, Name, Location
      FROM Loader WHERE Bar_Code = ${barcode}
      ORDER BY Date DESC, Time DESC
    `;

    if (result1.recordset.length > 0) {
      const combinedData = {
        ...result1.recordset[0],
        ...(result2.recordset[0] || {}),
      };
      res.json({ status: 'success', data: [combinedData] });
    } else {
      res.json({ status: 'not_found', message: 'No data found from PalletSlip' });
    }
  } catch (err) {
    console.error('Search error:', err);
    res.status(500).json({ status: 'error', message: 'Server error' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

app.post('/submit-status-loader', async (req, res) => {
  const { slip_no, date, time, bar_code, name , check_in , check_out, location } = req.body;

  if (
    !bar_code?.trim() ||
    !name?.trim() ||
    !location?.trim() ||
    !['yes', 'no'].includes(check_in) ||
    !['yes', 'no'].includes(check_out)
  ) {
    return res.status(400).json({ status: 'error', message: 'Incomplete or incorrect information' });
  }

  try {
    await sql.connect(dbConfig);

    await sql.query`
      INSERT INTO Loader (Slip_No, Date, Time, Bar_Code, Check_In, Check_Out, Name, Location)
      VALUES (${slip_no}, ${date}, ${time}, ${bar_code}, ${check_in}, ${check_out}, ${name}, ${location})
    `;

    res.json({ status: 'success', message: 'Data has been recorded successfully.' });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ status: 'error', message: 'An error occurred in the system.' });
  } finally {
    if (sql.connected) await sql.close();
  }
});

// 📈 API สำหรับโหลดข้อมูล Pie Chart
// 📈 API for loading Pie Chart data
app.get('/loader-stats', async (req, res) => {
  try {
    const pool = await sql.connect(dbConfig);

    const result = await pool.request().query(`
      SELECT 
        (SELECT COUNT(CASE WHEN Check_In = 'yes' THEN 1 END) FROM Loader ) AS check_in,
        (SELECT COUNT(CASE WHEN Check_Out = 'yes' THEN 1 END) FROM Loader ) AS check_out,
        (SELECT COUNT(*) FROM Checker  WHERE Approved = 'yes' AND Bar_Code NOT IN (SELECT Bar_Code FROM Loader)) AS not_checked
    `);

    const row = result.recordset[0];

    res.json({
      status: 'success',
      data: {
        checkIn: row.check_in,
         checkOut: row.check_out,
        notChecked: row.not_checked
      }
    });
  } catch (err) {
    console.error('Database error:', err);
    res.status(500).json({ status: 'error', message: 'Internal Server Error' });
  }
});

// API ping เพื่อตรวจสอบสถานะการเชื่อมต่อ
// Ping API to check connection status
app.get('/ping', (req, res) => {
  res.json({ status: 'ok' });
});

// เริ่มเซิร์ฟเวอร์
// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`API server is running on http://localhost:${port}`);
});