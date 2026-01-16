-- 0. khởi tạo cơ sở dữ liệu
create database if not exists studentmanagement;
use studentmanagement;

-- i. cấu trúc database
-- 1. bảng students
create table students (
    studentid char(5) primary key,
    fullname varchar(50) not null,
    totaldebt decimal(10,2) default 0
);

-- 2. bảng subjects
create table subjects (
    subjectid char(5) primary key,
    subjectname varchar(50) not null,
    credits int check (credits > 0)
);

-- 3. bảng grades
create table grades (
    studentid char(5),
    subjectid char(5),
    score decimal(4,2) check (score between 0 and 10),
    primary key (studentid, subjectid),
    foreign key (studentid) references students(studentid),
    foreign key (subjectid) references subjects(subjectid)
);

-- 4. bảng gradelog
create table gradelog (
    logid int primary key auto_increment,
    studentid char(5),
    oldscore decimal(4,2),
    newscore decimal(4,2),
    changedatea datetime default current_timestamp
);

-- dữ liệu mẫu để kiểm tra
insert into students (studentid, fullname, totaldebt) values ('sv01', 'nguyen van a', 3000000);
insert into subjects (subjectid, subjectname, credits) values ('mh01', 'co so du lieu', 3);

---------------------------------------------------------
-- ii. nội dung yêu cầu
---------------------------------------------------------

-- phần a – cơ bản
-- câu 1: trigger kiểm tra điểm hợp lệ
delimiter //
create trigger tg_checkscore
before insert on grades
for each row
begin
    if new.score < 0 then
        set new.score = 0;
    elseif new.score > 10 then
        set new.score = 10;
    end if;
end //
delimiter ;

-- câu 2: transaction thêm sinh viên mới
start transaction;
insert into students (studentid, fullname, totaldebt) 
values ('sv02', 'ha bich ngoc', 0);

update students 
set totaldebt = 5000000 
where studentid = 'sv02';
commit;

---------------------------------------------------------
-- phần b – khá
-- câu 3: trigger ghi lịch sử sửa điểm
delimiter //
create trigger tg_loggradeupdate
after update on grades
for each row
begin
    if old.score <> new.score then
        insert into gradelog (studentid, oldscore, newscore, changedatea)
        values (old.studentid, old.score, new.score, now());
    end if;
end //
delimiter ;

-- câu 4: procedure đóng học phí
delimiter //
create procedure sp_paytuition()
begin
    declare current_debt decimal(10,2);
    
    start transaction;
    
    update students 
    set totaldebt = totaldebt - 2000000 
    where studentid = 'sv01';
    
    select totaldebt into current_debt from students where studentid = 'sv01';
    
    if current_debt < 0 then
        rollback;
    else
        commit;
    end if;
end //
delimiter ;

---------------------------------------------------------
-- phần c – giỏi
-- câu 5: trigger ngăn sửa điểm khi đã qua môn
delimiter //
create trigger tg_preventpassupdate
before update on grades
for each row
begin
    if old.score >= 4.0 then
        signal sqlstate '45000' 
        set message_text = 'khong the sua diem vi sinh vien da qua mon';
    end if;
end //
delimiter ;

-- câu 6: procedure xóa môn học an toàn
delimiter //
create procedure sp_deletestudentgrade(
    in p_studentid char(5), 
    in p_subjectid char(5)
)
begin
    start transaction;
    
    -- lưu vết vào gradelog trước khi xóa
    insert into gradelog (studentid, oldscore, newscore, changedatea)
    select studentid, score, null, now()
    from grades 
    where studentid = p_studentid and subjectid = p_subjectid;
    
    -- thực hiện xóa
    delete from grades 
    where studentid = p_studentid and subjectid = p_subjectid;
    
    -- kiểm tra xem có dòng nào bị xóa không
    if row_count() = 0 then
        rollback;
    else
        commit;
    end if;
end //
delimiter ;
