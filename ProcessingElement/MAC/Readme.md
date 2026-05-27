# MAC unit 
This unit is used to performs an hardware multiply and accumulate operation. The main requirements are: 
- INT8 data format (FP16 may be considerated in future works if enough area).
- Radix-4 Booth encorder for generating patials (Radix-8 may be considered only if does not introduce too much complexity).
- Dadda tree for the partial sums (Wallace tree generates too much complexity and area).
- Carry Look-ahead or final sum (carry-skip may be considered to reduce area).

The MAC unit should be small enough to achieve a large enough systolic array and process data with high troughput.
<p align=center>
  <img width="642" height="226" alt="MAC" src="https://github.com/user-attachments/assets/51334e96-f597-45cf-9f01-1f45e34d4e18" />
</p>
