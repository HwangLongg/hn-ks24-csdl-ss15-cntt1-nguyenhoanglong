CREATE DATABASE StudentDB;
USE StudentDB;
-- 1. Bảng Khoa
CREATE TABLE Department (
    DeptID CHAR(5) PRIMARY KEY,
    DeptName VARCHAR(50) NOT NULL
);

-- 2. Bảng SinhVien
CREATE TABLE Student (
    StudentID CHAR(6) PRIMARY KEY,
    FullName VARCHAR(50),
    Gender VARCHAR(10),
    BirthDate DATE,
    DeptID CHAR(5),
    FOREIGN KEY (DeptID) REFERENCES Department(DeptID)
);

-- 3. Bảng MonHoc
CREATE TABLE Course (
    CourseID CHAR(6) PRIMARY KEY,
    CourseName VARCHAR(50),
    Credits INT
);

-- 4. Bảng DangKy
CREATE TABLE Enrollment (
    StudentID CHAR(6),
    CourseID CHAR(6),
    Score FLOAT,
    PRIMARY KEY (StudentID, CourseID),
    FOREIGN KEY (StudentID) REFERENCES Student(StudentID),
    FOREIGN KEY (CourseID) REFERENCES Course(CourseID)
);
INSERT INTO Department VALUES
('IT','Information Technology'),
('BA','Business Administration'),
('ACC','Accounting');

INSERT INTO Student VALUES
('S00001','Nguyen An','Male','2003-05-10','IT'),
('S00002','Tran Binh','Male','2003-06-15','IT'),
('S00003','Le Hoa','Female','2003-08-20','BA'),
('S00004','Pham Minh','Male','2002-12-12','ACC'),
('S00005','Vo Lan','Female','2003-03-01','IT'),
('S00006','Do Hung','Male','2002-11-11','BA'),
('S00007','Nguyen Mai','Female','2003-07-07','ACC'),
('S00008','Tran Phuc','Male','2003-09-09','IT');

INSERT INTO Course VALUES
('C00001','Database Systems',3),
('C00002','C Programming',3),
('C00003','Microeconomics',2),
('C00004','Financial Accounting',3);

INSERT INTO Enrollment VALUES
('S00001','C00001',8.5),
('S00001','C00002',7.0),
('S00002','C00001',6.5),
('S00003','C00003',7.5),
('S00004','C00004',8.0),
('S00005','C00001',9.0),
('S00006','C00003',6.0),
('S00007','C00004',7.0),
('S00008','C00001',5.5),
('S00008','C00002',6.5);

-- phần a – cơ bản

-- câu 1: tạo view_studentbasic và truy vấn
create view view_studentbasic as
select s.studentid, s.fullname, d.deptname
from student s
join department d on s.deptid = d.deptid;

select * from view_studentbasic;

-- câu 2: tạo regular index cho cột fullname
create index idx_fullname on student(fullname);

-- câu 3: stored procedure getstudentsit
delimiter //
create procedure getstudentsit()
begin
    select s.*, d.deptname
    from student s
    join department d on s.deptid = d.deptid
    where d.deptname = 'information technology';
end //
delimiter ;

call getstudentsit();

-- phần b – khá

-- câu 4: thống kê sinh viên theo khoa
-- a) tạo view
create view view_studentcountbydept as
select d.deptname, count(s.studentid) as totalstudents
from department d
left join student s on d.deptid = s.deptid
group by d.deptname;

-- b) truy vấn khoa có nhiều sinh viên nhất
select * from view_studentcountbydept
where totalstudents = (select max(totalstudents) from view_studentcountbydept);

-- câu 5: stored procedure gettopscorestudent
delimiter //
create procedure gettopscorestudent(in p_courseid char(6))
begin
    select s.studentid, s.fullname, e.score
    from student s
    join enrollment e on s.studentid = e.studentid
    where e.courseid = p_courseid
    and e.score = (select max(score) from enrollment where courseid = p_courseid);
end //
delimiter ;

-- b) gọi thủ tục cho môn database systems
call gettopscorestudent('c00001');

-- phần c – giỏi

-- bài 6: quản lý cập nhật điểm
-- a) tạo view với with check option
create view view_it_enrollment_db as
select e.studentid, e.courseid, e.score
from enrollment e
join student s on e.studentid = s.studentid
where s.deptid = 'it' and e.courseid = 'c00001'
with check option;

-- b) viết stored procedure updatescore_it_db
delimiter //
create procedure updatescore_it_db(
    in p_studentid char(6), 
    inout p_newscore float
)
begin
    -- xử lý nếu điểm > 10
    if p_newscore > 10 then
        set p_newscore = 10;
    end if;

    -- cập nhật thông qua view
    update view_it_enrollment_db
    set score = p_newscore
    where studentid = p_studentid;
end //
delimiter ;

-- c) gọi thủ tục kiểm tra
-- khai báo biến nhận giá trị inout
set @current_score = 11;

-- gọi thủ tục cập nhật cho sinh viên s00001 (khoa it, môn c00001)
call updatescore_it_db('s00001', @current_score);

-- hiển thị giá trị điểm sau khi xử lý
select @current_score as score_after_call;

-- kiểm tra lại dữ liệu trong view
select * from view_it_enrollment_db;
