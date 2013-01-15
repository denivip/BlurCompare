//
//  DVFrameworkChooseController.m
//  BlurTest
//
//  Created by Mikhail Grushin on 15.01.13.
//  Copyright (c) 2013 Mikhail Grushin. All rights reserved.
//

#import "DVFrameworkChooseController.h"
#import "DVTestViewController.h"

@implementation DVFrameworkChooseController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    switch (indexPath.row) {
        case DVCoreImage:
            cell.textLabel.text = @"Core Image";
            break;
            
        case DVAccelerate:
            cell.textLabel.text = @"Accelerate vImage";
            break;
            
        case DVGPUImage:
            cell.textLabel.text = @"GPUImage";
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.navigationController pushViewController:[[DVTestViewController alloc] initWithFramework:indexPath.row]
                                         animated:YES];
}

@end
