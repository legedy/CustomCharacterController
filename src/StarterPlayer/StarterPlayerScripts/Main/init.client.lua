local Fatnoid = require(script:WaitForChild('Fatnoid'));

local start = os.clock();
Fatnoid:Init();
print('Initialized in ' ..((os.clock() - start) * 1000).. ' milliseconds.');